/**
 * BE WTR — Guide Technicien
 * Collecteur des retours (bugs & suggestions) de l'onglet « Signaler / suggérer ».
 *
 * A coller dans Extensions > Apps Script d'un Google Sheet, puis deployer en
 * application web. Mode d'emploi complet : FEEDBACK-SETUP.md
 */

/* ------------------------------------------------------------------ CONFIG */

/** Nom de l'onglet du classeur ou sont ecrits les retours (cree si absent). */
var SHEET_NAME = 'Retours';

/** Doit correspondre a FEEDBACK_TOKEN dans index.html.
 *  Laisser '' des deux cotes pour desactiver la verification. */
var SHARED_TOKEN = '';

/** Adresse prevenue a chaque nouveau retour ('' = aucune notification). */
var NOTIFY_EMAIL = '';

var HEADERS = ['Date', 'Type', 'Section', 'Machine', 'Message',
               'Nom', 'Email', 'Langue', 'Statut', 'Page', 'Ecran', 'Navigateur'];

/* ------------------------------------------------------------- POINTS D'ENTREE */

function doPost(e) {
  var lock = LockService.getScriptLock();
  try {
    // evite que deux envois simultanes s'ecrasent sur la meme ligne
    lock.waitLock(30000);

    if (!e || !e.postData || !e.postData.contents) throw new Error('empty body');
    var d = JSON.parse(e.postData.contents);

    if (SHARED_TOKEN && d.token !== SHARED_TOKEN) throw new Error('bad token');

    var message = trim_(d.message, 4000);
    if (!message) throw new Error('empty message');

    getSheet_().appendRow([
      d.sentAt ? new Date(d.sentAt) : new Date(),
      d.kind === 'suggestion' ? 'Suggestion' : 'Bug',
      safe_(trim_(d.areaLabel, 120)),
      safe_(trim_(d.machine, 60)),
      safe_(message),
      safe_(trim_(d.name, 120)),
      safe_(trim_(d.email, 160)),
      safe_(trim_(d.lang, 5)),
      'Nouveau',
      safe_(trim_(d.page, 300)),
      safe_(trim_(d.screen, 30)),
      safe_(trim_(d.userAgent, 400))
    ]);

    notify_(d, message);
    return json_({ ok: true });

  } catch (err) {
    return json_({ ok: false, error: String(err && err.message || err) });
  } finally {
    try { lock.releaseLock(); } catch (ignored) {}
  }
}

/** Permet de verifier dans un navigateur que le deploiement repond. */
function doGet() {
  return json_({ ok: true, service: 'bewtr-feedback' });
}

/* ------------------------------------------------------------------ OUTILS */

function getSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sh = ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);
  if (sh.getLastRow() === 0) {
    sh.appendRow(HEADERS);
    sh.getRange(1, 1, 1, HEADERS.length).setFontWeight('bold').setBackground('#f6f8fa');
    sh.setFrozenRows(1);
    sh.setColumnWidth(1, 150);   // Date
    sh.setColumnWidth(5, 460);   // Message
    sh.getRange(1, 5, sh.getMaxRows()).setWrap(true);
  }
  return sh;
}

function trim_(v, max) {
  return String(v == null ? '' : v).trim().slice(0, max);
}

/**
 * Neutralise les valeurs que Sheets interpreterait comme une formule.
 * Sans ca, un retour commencant par « = » deviendrait une formule dans la cellule.
 */
function safe_(v) {
  return /^[=+\-@]/.test(v) ? "'" + v : v;
}

function notify_(d, message) {
  if (!NOTIFY_EMAIL) return;
  try {
    var kind = d.kind === 'suggestion' ? 'Suggestion' : 'Bug';
    MailApp.sendEmail({
      to: NOTIFY_EMAIL,
      subject: '[Guide Technicien] ' + kind + (d.areaLabel ? ' — ' + d.areaLabel : ''),
      body: [
        'Type     : ' + kind,
        'Section  : ' + (d.areaLabel || '-'),
        'Machine  : ' + (d.machine || '-'),
        'De       : ' + (d.name || 'anonyme') + (d.email ? ' <' + d.email + '>' : ''),
        'Langue   : ' + (d.lang || '-'),
        '',
        message,
        '',
        SpreadsheetApp.getActiveSpreadsheet().getUrl()
      ].join('\n')
    });
  } catch (err) {
    // une notification qui echoue ne doit jamais faire perdre le retour
  }
}

function json_(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
