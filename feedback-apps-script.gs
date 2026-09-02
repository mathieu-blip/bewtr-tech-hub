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
 *  Laisser '' des deux cotes pour desactiver la verification.
 *
 *  Sans jeton, l'URL du service — qui est lisible dans la page — suffit a
 *  ecrire ce qu'on veut dans la feuille. Le pot de miel du formulaire ne vit
 *  que dans le navigateur : il ne protege rien de qui construit l'URL a la
 *  main. Ce jeton-la, si. */
var SHARED_TOKEN = 'bewtr-fb-x_j2flsjppp_-ybVO-oP_XnU';

/** Adresse prevenue a chaque nouveau retour ('' = aucune notification). */
var NOTIFY_EMAIL = '';

var HEADERS = ['Date', 'Type', 'Section', 'Machine', 'Message',
               'Nom', 'Email', 'Langue', 'Statut', 'Page', 'Ecran', 'Navigateur'];

/* ------------------------------------------------------------- POINTS D'ENTREE */

/**
 * Le guide envoie en GET, donnees dans l'URL.
 *
 * Apps Script repond par une redirection interne, et une redirection abandonne
 * le corps d'un POST en route : doPost recevait une requete vide. Les
 * parametres d'URL, eux, traversent la redirection intacts.
 *
 * Sans parametre, repond l'etat du service : c'est le test a faire dans un
 * navigateur pour verifier que le deploiement est vivant.
 */
function doGet(e) {
  if (!e || !e.parameter || !e.parameter.message) {
    return json_({ ok: true, service: 'bewtr-feedback' });
  }
  return record_(e.parameter);
}

/** Conserve pour compatibilite : accepte encore un POST en JSON. */
function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) throw new Error('empty body');
    return record_(JSON.parse(e.postData.contents));
  } catch (err) {
    return json_({ ok: false, error: String(err && err.message || err) });
  }
}

/** Ecrit une ligne. `recorded` distingue un envoi enregistre d'un simple accuse. */
function record_(d) {
  var lock = LockService.getScriptLock();
  try {
    // evite que deux envois simultanes s'ecrasent sur la meme ligne
    lock.waitLock(30000);

    if (SHARED_TOKEN && d.token !== SHARED_TOKEN) throw new Error('bad token');

    var message = trim_(d.message, 2000);
    if (!message) throw new Error('empty message');

    getSheet_().appendRow([
      parseDate_(d.sentAt),
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
    return json_({ ok: true, recorded: true });

  } catch (err) {
    return json_({ ok: false, error: String(err && err.message || err) });
  } finally {
    try { lock.releaseLock(); } catch (ignored) {}
  }
}

/** Une date d'envoi illisible ne doit pas faire perdre le retour. */
function parseDate_(v) {
  if (!v) return new Date();
  var d = new Date(v);
  return isNaN(d.getTime()) ? new Date() : d;
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
