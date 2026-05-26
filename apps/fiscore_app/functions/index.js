const tenants = require("./tenants");
const team = require("./team");
const sites = require("./sites");
const audits = require("./audits");
const attachments = require("./attachments");
const library = require("./library");
const actions = require("./actions");
const violations = require("./violations");
const training = require("./training");

module.exports = {
  ...tenants,
  ...team,
  ...sites,
  ...audits,
  ...attachments,
  ...library,
  markOverdueTrainingActions: actions.markOverdueTrainingActions,
  markOverdueAuditActions: actions.markOverdueAuditActions,
  ...violations,
  ...training,
};
