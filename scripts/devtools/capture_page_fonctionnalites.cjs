// Captures d'écran de la page fonctionnalités, pour app/assets/images/rdv_mairie/.
//
// Prérequis :
//   - les seeds sont chargés (bin/rails db:seed), le serveur tourne (port WEB_PORT, 3000 par défaut)
//   - les variables d'agent du seed sont dans .env (mot de passe DB_SEEDS_USERS_AND_AGENTS_PASSWORD)
//   - playwright installé (node_modules) et cwebp disponible (apt-get install webp)
//
// Usage : node scripts/devtools/capture_page_fonctionnalites.cjs
//
// Le script commence par lancer scripts/devtools/setup_capture_fonctionnalites.rb, qui crée
// les données de démo manquantes (RDV collectif, invitation) et affiche le lien public de
// l'organisation, l'id du RDV collectif et le jeton de l'invitation.
//
// Les PNG sont générés dans /tmp puis convertis en webp dans app/assets/images/rdv_mairie/.
// Les images sont en 16:9 (viewport 1440×810, deviceScaleFactor 2), comme figure.fr-content-media
// les impose au rendu. Les captures mobiles (parcours usager) sont d'abord prises en
// 390×844 puis incrustées sur un fond neutre 16:9 pour éviter tout étirement.
//
// En dev, Propshaft sert depuis public/assets/.manifest.json s'il existe (resolver statique) :
// après l'ajout d'une image il faut recalculer le digest, copier le fichier digéré et mettre à
// jour le manifest. En production, la precompile fait tout ça à partir du fichier source.

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const { chromium } = require(path.join(__dirname, "..", "..", "node_modules", "playwright"));

const BASE = `http://www.rdv-mairie.localhost:${process.env.WEB_PORT || 3000}`;
const AGENT_EMAIL = "aferreira@mairie.rdv.fr";
const ORG_ID = 31;          // Mairie de Sannois (seed rdv_mairie)
const MOTIF_ID = 1068;      // Passeport
const USER_ID = 10010;      // premier usager de l'organisation
const LIEU_ID = 109;
const USAGER_EMAIL = "ybenamar@mairie.rdv.fr";
const PASSWORD = process.env.DB_SEEDS_USERS_AND_AGENTS_PASSWORD || "Rdvservicepublictest1!";
const FROM_DATE = new Date(Date.now() + 24 * 3600 * 1000).toISOString().slice(0, 10);

// Les trois bandeaux propres à l'environnement local, cf AGENTS.md
const MASK_CSS = ".rdv-solidarites-instance-name-wrapper, .profiler-results, .fr-notice--info { display: none !important; }";

const VIEWPORTS = {
  desktop: { width: 1440, height: 810, deviceScaleFactor: 2 },
  mobile: { width: 390, height: 844, deviceScaleFactor: 2 },
};

async function nouveauContexte(browser, vue) {
  const ctx = await browser.newContext({
    viewport: { width: VIEWPORTS[vue].width, height: VIEWPORTS[vue].height },
    deviceScaleFactor: VIEWPORTS[vue].deviceScaleFactor,
    locale: "fr-FR",
  });
  await ctx.addInitScript((css) => {
    const style = document.createElement("style");
    style.textContent = css;
    document.addEventListener("DOMContentLoaded", () => document.head.appendChild(style));
  }, MASK_CSS);
  return ctx;
}

function railsRunner(script) {
  return execSync(`bin/rails runner '${script}'`, { cwd: path.join(__dirname, "..", "..") }).toString().trim();
}

async function connexionAgent(page) {
  await page.goto(`${BASE}/agents/sign_in`, { waitUntil: "networkidle", timeout: 60000 });
  await page.fill('input[name="agent[email]"]', AGENT_EMAIL);
  await page.fill('input[name="agent[password]"]', PASSWORD);
  await Promise.all([page.waitForNavigation({ waitUntil: "networkidle" }), page.click('input[type="submit"]')]);
}

// Connexion usager par code reçu par email : le code est lisible en base en dev.
async function connexionUsagerParCode(page) {
  await page.goto(`${BASE}/users/sign_in`, { waitUntil: "networkidle", timeout: 60000 });
  await page.fill('input[name="login_code_request_form[email]"]', USAGER_EMAIL);
  await Promise.all([page.waitForNavigation({ waitUntil: "networkidle" }), page.click('input[type="submit"]')]);
  const code = railsRunner(`print LoginCode.most_recent_usable_for(email: "${USAGER_EMAIL}").code`);
  await page.fill('input[name="login_code[code]"]', code);
  await Promise.all([page.waitForNavigation({ waitUntil: "networkidle" }), page.click('input[type="submit"]')]);
}

// Incruste une capture mobile sur un fond neutre 16:9 (1440×810) et remplace le PNG.
async function incrusterMobile16x9(browser, pngPath) {
  const ctx = await browser.newContext({ viewport: VIEWPORTS.desktop, deviceScaleFactor: VIEWPORTS.desktop.deviceScaleFactor, locale: "fr-FR" });
  const page = await ctx.newPage();
  const html = `<!doctype html><html><head><meta charset="utf-8"></head>
    <body style="margin:0;background:#f6f6f6;height:100vh;display:flex;align-items:center;justify-content:center">
    <img src="${path.basename(pngPath)}" style="height:700px;border-radius:24px;border:10px solid #fff;box-shadow:0 8px 32px rgba(0,0,0,.18)">
    </body></html>`;
  fs.writeFileSync("/tmp/incrustation-mobile.html", html);
  await page.goto("file:///tmp/incrustation-mobile.html");
  await page.waitForSelector("img");
  await page.waitForTimeout(200);
  await page.screenshot({ path: pngPath });
  await ctx.close();
}

// Recherche de créneau côté agent : la recherche redirige directement vers la
// sélection (un seul lieu), on cadre sur la carte de créneaux.
async function captureRechercheCreneau(page) {
  await page.goto(
    `${BASE}/admin/organisations/${ORG_ID}/creneaux_search?user_ids[]=${USER_ID}&motif_id=${MOTIF_ID}&from_date=${FROM_DATE}&commit=commit`,
    { waitUntil: "networkidle", timeout: 90000 }
  );
  await page.waitForSelector(".creneau", { timeout: 30000 });
  await page.locator(".creneau").first().scrollIntoViewIfNeeded();
  await page.evaluate(() => window.scrollBy(0, -120));
  await page.waitForTimeout(400);
  await page.screenshot({ path: "/tmp/capture-recherche-creneau.png" });
}

// Statuts : page « à renseigner », avec le menu « Autre » ouvert (annulé usager / service)
async function captureStatutRdv(page) {
  await page.goto(`${BASE}/admin/organisations/${ORG_ID}/rdvs/a_renseigner`, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForSelector("turbo-frame.card", { timeout: 30000 });
  await page.locator('.dropdown-toggle:has-text("Autre")').first().click();
  await page.waitForTimeout(500);
  await page.locator("turbo-frame.card").first().scrollIntoViewIfNeeded();
  await page.evaluate(() => window.scrollBy(0, -180));
  await page.waitForTimeout(300);
  await page.screenshot({ path: "/tmp/capture-statut-rdv.png" });
}

async function captureMotifs(page) {
  await page.goto(`${BASE}/admin/organisations/${ORG_ID}/motifs/${MOTIF_ID}/edit`, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForSelector("form", { timeout: 30000 });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(300);
  await page.screenshot({ path: "/tmp/capture-motifs.png" });
}

async function captureUsagers(page) {
  await page.goto(`${BASE}/admin/organisations/${ORG_ID}/users/${USER_ID}`, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForTimeout(500);
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({ path: "/tmp/capture-usagers.png" });
}

// RDV collectif : la fiche du RDV avec la liste des participant·es.
async function captureRdvCollectif(page, rdvCollectifId) {
  await page.goto(`${BASE}/admin/organisations/${ORG_ID}/rdvs/${rdvCollectifId}`, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForSelector(".card", { timeout: 30000 });
  // La liste des participant·es est un tableau sous les détails du RDV : on le
  // remonte dans le viewport pour qu'il soit entier sur la capture.
  await page.evaluate(() => {
    const table = document.querySelector("table");
    const top = table.getBoundingClientRect().top + window.scrollY;
    window.scrollTo(0, Math.max(0, top - 240));
  });
  await page.waitForTimeout(400);
  await page.screenshot({ path: "/tmp/capture-rdv-collectifs.png" });
}

// Parcours usager public, en vue mobile : motif Passeport → nombre de pré-demandes ANTS →
// lieu → créneaux. L'API ANTS est mockée en dev (ANTS_RDV_API_MOCK_RESPONSES), aucun appel externe.
async function capturePriseRdvEnLigne(page, lienPublic) {
  await page.goto(`${BASE}/org/${lienPublic}`, { waitUntil: "networkidle", timeout: 60000 });
  await page.click("text=Passeport");
  await page.waitForLoadState("networkidle");
  await page.fill('input[name="ants_pre_demandes_count"]', "1");
  await Promise.all([page.waitForNavigation({ waitUntil: "networkidle" }), page.click('input[type="submit"]')]);
  const lieuHref = await page.evaluate((orgName) => {
    const a = [...document.querySelectorAll("a")].find((x) => x.textContent.includes(orgName) && x.href.includes("prendre_rdv") && x.href.includes("lieu"));
    return a ? a.href : null;
  }, "Mairie de Sannois");
  await page.goto(lieuHref, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForSelector("text=Sélectionnez un créneau", { timeout: 30000 });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(300);
  await page.screenshot({ path: "/tmp/capture-prise-rdv-en-ligne.png" });
}

// Numéro de pré-demande ANTS, en vue mobile : après le choix du créneau, l'étape
// « Pour qui prenez-vous rendez-vous ? » demande le numéro de pré-demande.
async function captureAnts(page, lienPublic) {
  await page.goto(`${BASE}/org/${lienPublic}`, { waitUntil: "networkidle", timeout: 60000 });
  await page.click("text=Passeport");
  await page.waitForLoadState("networkidle");
  await page.fill('input[name="ants_pre_demandes_count"]', "1");
  await Promise.all([page.waitForNavigation({ waitUntil: "networkidle" }), page.click('input[type="submit"]')]);
  const lieuHref = await page.evaluate((orgName) => {
    const a = [...document.querySelectorAll("a")].find((x) => x.textContent.includes(orgName) && x.href.includes("prendre_rdv") && x.href.includes("lieu"));
    return a ? a.href : null;
  }, "Mairie de Sannois");
  await page.goto(lieuHref, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForSelector("text=Sélectionnez un créneau", { timeout: 30000 });
  await Promise.all([
    page.waitForNavigation({ waitUntil: "networkidle", timeout: 60000 }),
    page.locator('a[aria-label^="Choisir le créneau"]').first().click(),
  ]);
  await page.waitForSelector("text=Pour qui prenez-vous rendez-vous ?", { timeout: 30000 });
  await page.locator("#selected_user_current").check();
  const champAnts = page.locator('input[name*="ants_pre_demande_number"]').first();
  if (await champAnts.inputValue() === "") {
    await champAnts.fill("ABCDE12345");
  }
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(300);
  await page.screenshot({ path: "/tmp/capture-ants.png" });
}

// Invitation, en vue mobile : la page sur laquelle arrive l'usager depuis le lien
// d'invitation envoyé par l'agent, pour choisir son créneau en autonomie.
async function captureInvitation(page, jeton) {
  await page.goto(`${BASE}/invit/${jeton}`, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForSelector('a[aria-label^="Choisir le créneau"]', { timeout: 30000 });
  await page.locator('a[aria-label^="Choisir le créneau"]').first().scrollIntoViewIfNeeded();
  await page.evaluate(() => window.scrollBy(0, -80));
  await page.waitForTimeout(300);
  await page.screenshot({ path: "/tmp/capture-invitations.png" });
}

(async () => {
  const setup = execSync("bin/rails runner scripts/devtools/setup_capture_fonctionnalites.rb", {
    cwd: path.join(__dirname, "..", ".."),
  }).toString();
  const lienPublic = setup.match(/PUBLIC_LINK=(\S+)/)[1];
  const rdvCollectifId = setup.match(/RDV_COLLECTIF_ID=(\d+)/)[1];
  const jetonInvitation = setup.match(/INVITATION_TOKEN=(\S+)/)[1];
  console.log(`lien public : ${lienPublic}, rdv collectif : ${rdvCollectifId}, invitation : ${jetonInvitation}`);

  const browser = await chromium.launch();

  const agentCtx = await nouveauContexte(browser, "desktop");
  const agentPage = await agentCtx.newPage();
  await connexionAgent(agentPage);
  await captureRechercheCreneau(agentPage);
  await captureStatutRdv(agentPage);
  await captureMotifs(agentPage);
  await captureUsagers(agentPage);
  await captureRdvCollectif(agentPage, rdvCollectifId);
  await agentCtx.close();

  const userCtx = await nouveauContexte(browser, "mobile");
  const userPage = await userCtx.newPage();
  await capturePriseRdvEnLigne(userPage, lienPublic);
  await connexionUsagerParCode(userPage);
  await captureAnts(userPage, lienPublic);
  await captureInvitation(userPage, jetonInvitation);
  await userCtx.close();

  // Les captures mobiles sont incrutées sur un fond 16:9 pour éviter l'étirement
  for (const name of ["prise-rdv-en-ligne", "ants", "invitations"]) {
    await incrusterMobile16x9(browser, `/tmp/capture-${name}.png`);
  }
  await browser.close();

  for (const name of [
    "recherche-creneau", "statut-rdv", "motifs", "usagers", "rdv-collectifs",
    "prise-rdv-en-ligne", "ants", "invitations",
  ]) {
    const out = `app/assets/images/rdv_mairie/${name}.webp`;
    execSync(`cwebp -q 85 /tmp/capture-${name}.png -o ${out}`, { cwd: path.join(__dirname, "..", ".."), stdio: "inherit" });
    console.log(`converti : ${out}`);
  }
})().catch((e) => { console.error(e); process.exit(1); });
