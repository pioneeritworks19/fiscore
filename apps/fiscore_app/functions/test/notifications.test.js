const assert = require("node:assert/strict");
const test = require("node:test");

const {
  assertEmailEventIsEnabled,
  generateDedupeKey,
  normalizeLocale,
  renderEmailTemplate,
  templates,
} = require("../notifications");

test("all required email templates render in English and Spanish", () => {
  const requiredTemplateIds = [
    "passwordless_sign_in_link",
    "team_invite_created",
    "team_invite_resent",
    "workspace_created",
    "signed_in_no_workspace",
    "workspace_has_no_site",
  ];

  for (const templateId of requiredTemplateIds) {
    assert.deepEqual(Object.keys(templates[templateId]).sort(), ["en", "es"]);
    for (const locale of ["en", "es"]) {
      const rendered = renderEmailTemplate(templateId, locale, {
        actionUrl: "https://fiscore-dev.web.app/join",
        adminUrl: "https://admin.fiscore.app",
        appUrl: "https://fiscore-dev.web.app",
        inviterName: "Owner",
        roleLabel: "Manager",
        siteContext: "All restaurants",
        tenantName: "Demo Bistro",
        websiteUrl: "https://fiscore.app",
      });

      assert.equal(rendered.locale, locale);
      assert.notEqual(rendered.subject, "");
      assert.notEqual(rendered.text, "");
      assert.notEqual(rendered.html, "");
      assert.doesNotMatch(rendered.text, /\{\{/);
      assert.doesNotMatch(rendered.html, /\{\{/);
    }
  }
});

test("workspace-created email includes the expected onboarding guidance", () => {
  const rendered = renderEmailTemplate("workspace_created", "en", {
    adminUrl: "https://admin.fiscore.app",
    appUrl: "https://fiscore-dev.web.app",
    tenantName: "Demo Bistro",
    websiteUrl: "https://fiscore.app",
  });

  assert.match(rendered.subject, /workspace is ready/i);
  assert.match(rendered.text, /Demo Bistro/);
  assert.match(rendered.text, /add or link your first restaurant/i);
  assert.match(rendered.text, /https:\/\/fiscore-dev\.web\.app/);
  assert.match(rendered.text, /https:\/\/fiscore\.app/);
  assert.match(rendered.text, /https:\/\/admin\.fiscore\.app/);
});

test("email rendering escapes HTML placeholder values", () => {
  const rendered = renderEmailTemplate("workspace_has_no_site", "en", {
    appUrl: "https://fiscore-dev.web.app",
    tenantName: "<script>alert('x')</script>",
  });

  assert.match(rendered.text, /<script>alert\('x'\)<\/script>/);
  assert.match(rendered.html, /&lt;script&gt;alert\(&#39;x&#39;\)&lt;\/script&gt;/);
  assert.doesNotMatch(rendered.html, /<script>/);
});

test("unsupported locales fall back to English", () => {
  assert.equal(normalizeLocale("fr-CA"), "en");
  assert.equal(normalizeLocale("ES-mx"), "es");
  assert.equal(normalizeLocale(null), "en");
});

test("operational emails are opt-in only", () => {
  assert.doesNotThrow(() => {
    assertEmailEventIsEnabled("submitViolationForReview", "skip");
  });

  assert.throws(
    () => assertEmailEventIsEnabled("submitViolationForReview", "email"),
    /Email is not enabled for notification event submitViolationForReview/,
  );
});

test("dedupe key is stable and normalizes recipient email casing", () => {
  const input = {
    eventType: "workspace_created",
    targetType: "tenant",
    targetId: "tenant-1",
    recipientEmail: "OWNER@EXAMPLE.COM",
    channel: "email",
  };

  assert.equal(
    generateDedupeKey(input),
    "workspace_created:tenant:tenant-1:owner@example.com:email",
  );
});
