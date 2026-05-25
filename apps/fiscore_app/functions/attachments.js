const { onObjectFinalized } = require("firebase-functions/v2/storage");
const {
  admin,
  db,
  storageBucket,
  storageRegion,
  safeDeleteStorageFile,
} = require("./shared/runtime");

function violationAttachmentFromPath(objectPath) {
  const match = objectPath.match(
    /^tenants\/([^/]+)\/sites\/([^/]+)\/violations\/([^/]+)\/attachments\/([^/]+)\/original\.[^/]+$/i,
  );
  if (!match) {
    return null;
  }
  return {
    tenantId: match[1],
    siteId: match[2],
    violationId: match[3],
    attachmentId: match[4],
  };
}

const processViolationAttachmentImage = onObjectFinalized(
  {
    region: storageRegion,
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (event) => {
    const objectPath = event.data.name;
    const contentType = event.data.contentType || "";
    if (!objectPath || !contentType.startsWith("image/")) {
      return;
    }

    const attachment = violationAttachmentFromPath(objectPath);
    if (!attachment) {
      return;
    }

    const { tenantId, siteId, violationId, attachmentId } = attachment;
    const attachmentRef = db
      .doc(`tenants/${tenantId}/sites/${siteId}/violations/${violationId}`)
      .collection("attachments")
      .doc(attachmentId);
    const now = admin.firestore.FieldValue.serverTimestamp();
    const basePath = objectPath.replace(/\/original\.[^/]+$/i, "");
    const compressedPath = `${basePath}/image.jpg`;
    const thumbnailPath = `${basePath}/thumb.jpg`;
    const bucket = storageBucket();

    try {
      await attachmentRef.set(
        {
          status: "processing",
          processingStartedAt: now,
          updatedAt: now,
        },
        { merge: true },
      );

      const sharp = require("sharp");
      const [originalBuffer] = await bucket.file(objectPath).download();
      const image = sharp(originalBuffer, { failOn: "none" }).rotate();
      const metadata = await image.metadata();
      const compressedBuffer = await sharp(originalBuffer, { failOn: "none" })
        .rotate()
        .resize({
          width: 1600,
          height: 1600,
          fit: "inside",
          withoutEnlargement: true,
        })
        .jpeg({ quality: 76, mozjpeg: true })
        .toBuffer();
      const thumbnailBuffer = await sharp(originalBuffer, { failOn: "none" })
        .rotate()
        .resize({
          width: 360,
          height: 360,
          fit: "inside",
          withoutEnlargement: true,
        })
        .jpeg({ quality: 68, mozjpeg: true })
        .toBuffer();

      await bucket.file(compressedPath).save(compressedBuffer, {
        metadata: {
          contentType: "image/jpeg",
          metadata: {
            tenantId,
            siteId,
            violationId,
            attachmentId,
            source: "processed",
          },
        },
      });
      await bucket.file(thumbnailPath).save(thumbnailBuffer, {
        metadata: {
          contentType: "image/jpeg",
          metadata: {
            tenantId,
            siteId,
            violationId,
            attachmentId,
            source: "thumbnail",
          },
        },
      });

      await attachmentRef.set(
        {
          status: "ready",
          contentType: "image/jpeg",
          storagePath: compressedPath,
          compressedPath,
          thumbnailPath,
          sizeBytes: compressedBuffer.length,
          compressedSizeBytes: compressedBuffer.length,
          thumbnailSizeBytes: thumbnailBuffer.length,
          width: metadata.width || null,
          height: metadata.height || null,
          compression: {
            maxEdge: 1600,
            quality: 76,
            thumbnailMaxEdge: 360,
            thumbnailQuality: 68,
          },
          processedAt: now,
          updatedAt: now,
        },
        { merge: true },
      );

      await safeDeleteStorageFile(objectPath);
    } catch (error) {
      console.error("Failed to process violation attachment image", {
        objectPath,
        error,
      });
      await attachmentRef.set(
        {
          status: "failed",
          processingError: error.message || "Image processing failed.",
          updatedAt: now,
        },
        { merge: true },
      );
    }
  },
);

module.exports = { processViolationAttachmentImage };
