const tenants = require("./tenants");
const team = require("./team");
const sites = require("./sites");
const audits = require("./audits");
const attachments = require("./attachments");
const library = require("./library");

module.exports = {
  ...tenants,
  ...team,
  ...sites,
  ...audits,
  ...attachments,
  ...library,
};
