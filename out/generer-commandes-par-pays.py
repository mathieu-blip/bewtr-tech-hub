# -*- coding: utf-8 -*-
import csv, json
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

SCR="/tmp/claude-0/-home-user-bewtr-tech-hub/9d71d817-09e8-524b-89cc-8e99b6e4ed28/scratchpad"
OUT="/home/user/bewtr-tech-hub/out/BE-WTR_commandes-spare-parts-par-pays_2026-08-26.xlsx"
ref={r["ref"]:r for r in csv.DictReader(open("/home/user/bewtr-tech-hub/docs/audit-spare-parts-2022.csv",encoding="utf-8-sig"))}
BLUPURA_EUR={"750244":22.50,"750243":21.60,"150068":2.70,"750230":27.30,"130009":72.00,"810320":10.50,
 "130053":138.70,"130049":68.60,"140092":15.40,"140194":15.40,"150031":12.20,"150391":11.00,"150525":11.00,
 "150576":49.10,"150385":49.10,"150551":24.20,"150388":25.90,"150016":19.70,"810620":50.30,"810366":47.10}
def pchf(s):
    try: return float(ref.get(s,{}).get("prix_catalogue",""))
    except: return None
def peur(s): return BLUPURA_EUR.get(ref.get(s,{}).get("ref_fournisseur",""))

A="Arial"
H1=Font(name=A,size=14,bold=True); H2=Font(name=A,size=11,bold=True)
BASE=Font(name=A,size=10); BOLD=Font(name=A,size=10,bold=True)
ITAL=Font(name=A,size=9,italic=True,color="595959"); WB_=Font(name=A,size=10,bold=True,color="FFFFFF")
BLUE=Font(name=A,size=10,color="0000FF")
HDR=PatternFill("solid",fgColor="1F3864"); GREY=PatternFill("solid",fgColor="BFBFBF")
WARN=PatternFill("solid",fgColor="FFF2CC"); TOT=PatternFill("solid",fgColor="E2EFDA")
PAYS_F=PatternFill("solid",fgColor="D9E2F3")
t=Side(style="thin",color="BFBFBF"); BORD=Border(left=t,right=t,top=t,bottom=t)
MONEY='#,##0.00;(#,##0.00);-'; INT='#,##0;(#,##0);-'

def hdr(ws,row,labs,widths):
    for i,l in enumerate(labs,1):
        c=ws.cell(row=row,column=i,value=l); c.font=WB_; c.fill=HDR; c.border=BORD
        c.alignment=Alignment(horizontal="center",vertical="center",wrap_text=True)
    ws.row_dimensions[row].height=32
    for i,w in enumerate(widths,1): ws.column_dimensions[get_column_letter(i)].width=w
def titre(ws,txt,sub=None):
    ws["A1"]=txt; ws["A1"].font=H1
    if sub: ws["A2"]=sub; ws["A2"].font=ITAL

# ---- LIGNES : (pays, sku|None, libelle_si_pas_sku, qte, origine, item_monday, note)
L=[]
def add(pays,sku,lib,qte,orig,item,note="",eur_over=None,four_over=None,rf_over=None):
    L.append(dict(pays=pays,sku=sku,lib=lib,qte=qte,orig=orig,item=item,note=note,
                  eur_over=eur_over,four_over=four_over,rf_over=rf_over))

# FRANCE — commande Monday 12889411743
for s,q in [("BW-0416",5),("BW-0183",20),("BW-0184",6),("BW-0417",3),("BW-0429",30),("BW-0421",30),
            ("BW-0419",2),("BW-0420",2),("BW-0428",10),("BW-0186",20),("BW-0424",10),("BW-0425",5),
            ("BW-0426",5),("BW-0195",5)]:
    add("France",s,None,q,"Commande Monday","12889411743")
# FRANCE — déduites des claims
add("France",None,"Compresseur / recharge gaz BOX 80",1,"Claim ouvert","12759710752",
    "Aucun compresseur au référentiel BOX 80 — SKU à créer")
add("France",None,"Électrovanne d'entrée BOX 80",1,"Claim ouvert","12759640381",
    "Aucune électrovanne d'entrée au référentiel BOX 80 — SKU à créer")

# SUISSE — commande Monday 12889827793
add("Suisse",None,"Ventilateur BOX 20 / BOX 15 (Blupura 750244)",30,"Commande Monday","12889827793",
    "Choix validé : Blupura 750244 à 22,50 EUR. Pas de SKU BW — à créer.",eur_over=22.50,
    four_over="Blupura",rf_over="750244")
add("Suisse","BW-0301",None,20,"Commande Monday","12889827793",
    "Demandé en 230-12V ; BW-0301 est en 230V/24VDC. Choix validé.")
add("Suisse","BW-0507",None,15,"Commande Monday","12889827793","Ligne dupliquée dans Monday — 15 retenu.")
add("Suisse","BW-0164",None,20,"Commande Monday","12889827793","Ligne dupliquée dans Monday — 20 retenu.")
add("Suisse",None,"Sonde BOX PRO2 V2",20,"Commande Monday","12889827793",
    "Aucune sonde PRO2 au référentiel — SKU à renseigner.")
# SUISSE — déduites des claims
add("Suisse","BW-0179",None,1,"Claim ouvert","12217762646","Diagnostic technicien : « il faut sûrement changer l'électrovanne ».")
add("Suisse","BW-0974",None,1,"Claim ouvert","12345567586","« Fuite au chapeau de la gearbox » — BW-0974 = hat. Conditionné par 5.")
add("Suisse","BW-0994",None,1,"Claim ouvert","12891544139","« Carrosserie HS ». Pièce BOX 20 absente de la base prix 2022.")
add("Suisse",None,"Bouton BAR2 (position haut-droite)",1,"Claim ouvert","12498897081",
    "4 boutons BAR2 possibles (810695-810698) — position à préciser.")
add("Suisse",None,"Fuite CO2 BOX 20 — pièce à identifier",1,"Claim ouvert","12891695968",
    "Fuite long terme, pièce non diagnostiquée.")
# UK
add("UK","BW-0295",None,1,"Claim ouvert","12232314055","« Drip tray cracked and leaking ».")
# EMIRATS
add("Émirats","BW-0172",None,1,"Claim ouvert","18083626539","« Release pressure valve — new spare part needed ».")
add("Émirats",None,"Spare parts manual capper (Tower)",1,"Claim ouvert","10943979984",
    "Machine Tower / capper hors référentiel — SKU à créer.")

wb=Workbook()

# ================= COMMANDES PAR PAYS =================
ws=wb.active; ws.title="Commandes par pays"
titre(ws,"Pièces à commander par pays — SKU, référence fournisseur et désignation",
      "Board Monday « Technical troubleshooting » au 26.08.2026 : 2 commandes formalisées + pièces déduites des 53 claims ouverts. "
      "Cellule SKU grisée = référence à renseigner.")
hdr(ws,4,["Pays","SKU BW","Désignation","Réf. fournisseur","Fournisseur","Qté",
          "Prix cat. (CHF)","Prix achat (EUR)","Total CHF","Total EUR","Origine","Item Monday","Remarque"],
    [11,11,40,15,15,7,13,14,12,12,15,13,46])
r=5; first=r; pays_rows={}
for x in L:
    s=x["sku"]; d=ref.get(s,{}) if s else {}
    lib=d.get("designation") or x["lib"]
    rf=x["rf_over"] or d.get("ref_fournisseur") or ""
    fo=x["four_over"] or d.get("fournisseur") or ""
    pc=pchf(s) if s else None
    pe=x["eur_over"] if x["eur_over"] is not None else (peur(s) if s else None)
    ws.cell(row=r,column=1,value=x["pays"]).font=BOLD
    c=ws.cell(row=r,column=2,value=s or "")
    c.font=BOLD
    if not s: c.fill=GREY
    ws.cell(row=r,column=3,value=lib).font=BASE
    ws.cell(row=r,column=4,value=rf or "—").font=BASE
    ws.cell(row=r,column=5,value=fo or "—").font=BASE
    ws.cell(row=r,column=6,value=x["qte"]).font=BLUE
    ws.cell(row=r,column=7,value=pc).font=BASE
    ws.cell(row=r,column=8,value=pe).font=BASE
    ws.cell(row=r,column=9,value=f'=IF(N(G{r})=0,"",F{r}*G{r})').font=BASE
    ws.cell(row=r,column=10,value=f'=IF(N(H{r})=0,"",F{r}*H{r})').font=BASE
    ws.cell(row=r,column=11,value=x["orig"]).font=BASE
    ws.cell(row=r,column=12,value=x["item"]).font=BASE
    ws.cell(row=r,column=13,value=x["note"]).font=BASE
    for cc in range(1,14):
        cell=ws.cell(row=r,column=cc); cell.border=BORD
        cell.alignment=Alignment(wrap_text=(cc in(3,13)),vertical="top")
    for cc in(7,8,9,10): ws.cell(row=r,column=cc).number_format=MONEY
    ws.cell(row=r,column=6).number_format=INT
    if x["note"]: ws.cell(row=r,column=13).fill=WARN
    pays_rows.setdefault(x["pays"],[]).append(r)
    r+=1
last=r-1
ws.cell(row=r,column=1,value="TOTAL").font=BOLD
ws.cell(row=r,column=6,value=f"=SUM(F{first}:F{last})").font=BOLD
ws.cell(row=r,column=9,value=f"=SUM(I{first}:I{last})").font=BOLD
ws.cell(row=r,column=10,value=f"=SUM(J{first}:J{last})").font=BOLD
ws.cell(row=r,column=13,value=f'=COUNTBLANK(B{first}:B{last})&" SKU à renseigner"').font=BOLD
for cc in range(1,14):
    cell=ws.cell(row=r,column=cc); cell.border=BORD; cell.fill=TOT
ws.cell(row=r,column=6).number_format=INT
for cc in(9,10): ws.cell(row=r,column=cc).number_format=MONEY
GRAND=r
ws.freeze_panes="A5"; ws.auto_filter.ref=f"A4:M{last}"

r+=2
ws.cell(row=r,column=1,value="Cellule SKU grisée : pièce identifiée mais sans référence BE WTR — à créer ou à faire préciser avant commande.").font=ITAL
r+=1
ws.cell(row=r,column=1,value="Prix cat. (CHF) = prix catalogue BE WTR, base septembre 2022. Prix achat (EUR) = liste fournisseur Blupura 2022. "
        "Vide = prix non publié (« AS* ») : devis fournisseur nécessaire.").font=ITAL
r+=1
ws.cell(row=r,column=1,value="Bleu = quantité issue de Monday. Noir = donnée du référentiel ou calcul.").font=ITAL

# ================= SYNTHESE PAR PAYS =================
ws=wb.create_sheet("Synthèse",0)
titre(ws,"Commandes de pièces détachées par pays","Extrait du board Monday « Technical troubleshooting » le 26.08.2026.")
hdr(ws,4,["Pays","Lignes","Pièces","dont commande Monday","dont claim ouvert","SKU à renseigner","Claims ouverts"],
    [14,9,10,22,20,18,16])
CLAIMS_OUV={"Suisse":38,"France":10,"Émirats":2,"UK":1,"Espagne":1,"Canada":1}
r=5
for pays in ["France","Suisse","UK","Émirats","Espagne","Canada"]:
    rows=pays_rows.get(pays,[])
    lignes=[x for x in L if x["pays"]==pays]
    ws.cell(row=r,column=1,value=pays).font=BOLD
    ws.cell(row=r,column=2,value=len(lignes)).font=BASE
    ws.cell(row=r,column=3,value=sum(x["qte"] for x in lignes)).font=BASE
    ws.cell(row=r,column=4,value=sum(x["qte"] for x in lignes if x["orig"]=="Commande Monday")).font=BASE
    ws.cell(row=r,column=5,value=sum(x["qte"] for x in lignes if x["orig"]=="Claim ouvert")).font=BASE
    ws.cell(row=r,column=6,value=sum(1 for x in lignes if not x["sku"])).font=BASE
    ws.cell(row=r,column=7,value=CLAIMS_OUV.get(pays,0)).font=BASE
    for cc in range(1,8):
        cell=ws.cell(row=r,column=cc); cell.border=BORD
        if cc>1: cell.number_format=INT
    r+=1
ws.cell(row=r,column=1,value="TOTAL").font=BOLD
for cc in range(2,8):
    Lt=get_column_letter(cc)
    ws.cell(row=r,column=cc,value=f"=SUM({Lt}5:{Lt}{r-1})").font=BOLD
    ws.cell(row=r,column=cc).number_format=INT
for cc in range(1,8):
    cell=ws.cell(row=r,column=cc); cell.border=BORD; cell.fill=TOT
r+=2
ws.cell(row=r,column=1,value="Montant chiffrable (CHF)").font=H2
ws.cell(row=r,column=3,value=f"='Commandes par pays'!I{GRAND}").font=BOLD
ws.cell(row=r,column=3).number_format=MONEY
r+=1
ws.cell(row=r,column=1,value="Montant chiffrable (EUR)").font=H2
ws.cell(row=r,column=3,value=f"='Commandes par pays'!J{GRAND}").font=BOLD
ws.cell(row=r,column=3).number_format=MONEY
r+=2
for txt in [
 "Espagne et Canada n'ont aucune pièce à commander : le claim espagnol est vide (« Ajouter subject ») et le claim canadien attend un frigoriste local.",
 "France : la commande couvre les pannes remontées, sauf deux écarts — 4 moteurs de pompe CO2 sont en panne pour 3 commandés, et 20 thermostats sont commandés pour 3 pannes.",
 "Décisions validées le 26.08.2026 : carte PRO1 = BW-0164 (195 CHF), ventilateur BOX 20 = Blupura 750244 (22,50 EUR), "
 "transformateur PRO2 = BW-0301, ramasse-goutte = BW-0507, lignes Monday dupliquées lues comme doublons de saisie, "
 "panneaux tactiles PRO2 exclus de la commande.",
]:
    c=ws.cell(row=r,column=1,value=txt); c.font=BASE
    c.alignment=Alignment(wrap_text=True,vertical="top")
    ws.merge_cells(start_row=r,start_column=1,end_row=r+1,end_column=7)
    r+=3

# ================= VERIFICATION DES 53 CLAIMS =================
ws=wb.create_sheet("Vérification claims")
titre(ws,"Vérification des 53 lignes ouvertes du Monday",
      "Statuts non clôturés au 26.08.2026 : New (to repair) 47, In progress 3, At supplier 2, Stucked 1.")
hdr(ws,4,["Item","Pays","Produit","Date","Statut","Sujet","Description","Verdict","Pièce retenue"],
    [13,11,26,11,16,32,52,30,30])
op=json.load(open(f"{SCR}/open53.json"))
VERDICT={
 "12889411743":("Commande formalisée","14 SKU BOX 80"),
 "12889827793":("Commande formalisée","5 lignes"),
 "12759710752":("Pièce déduite","Compresseur/gaz — SKU à créer"),
 "12759640381":("Pièce déduite","Électrovanne entrée — SKU à créer"),
 "12217762646":("Pièce déduite","BW-0179 PRO2 Solenoids"),
 "12345567586":("Pièce déduite","BW-0974 Gearbox - Hat"),
 "12891544139":("Pièce déduite","BW-0994 Outer casing BOX 20"),
 "12498897081":("Pièce déduite","Bouton BAR2 — position à préciser"),
 "12891695968":("Pièce déduite","Fuite CO2 — à diagnostiquer"),
 "12232314055":("Pièce déduite","BW-0295 BAR2 Drip tray"),
 "18083626539":("Pièce déduite","BW-0172 8mm PRV"),
 "10943979984":("Pièce déduite","Capper Tower — SKU à créer"),
 "12890647974":("Couvert par la commande","Ventilateur BOX 20 (30 pcs)"),
 "12189511251":("Couvert par la commande","Ventilateur BOX 20 (30 pcs)"),
 "12891290504":("Exclu sur décision","Panneau tactile PRO2"),
 "12488288189":("Exclu sur décision","Panneau tactile PRO2"),
 "12488429466":("Sans pièce","Machine échangée, pas de pièce"),
 "9340197921":("Sans pièce","Attente frigoriste local"),
 "12890697274":("Sans pièce","Claim vide"),
}
PAYS_FR={"Switzerland":"Suisse","France":"France","UK":"UK","United Arab Emirates":"Émirats",
         "Spain":"Espagne","Canada":"Canada"}
FR_SYM={"12734652195":"Moteur pompe CO2 + thermostat","12759584213":"Ventilateur + froid",
 "12759667201":"Moteur pompe CO2","12759598322":"Ventilateur + froid","12759621953":"Moteur pompe CO2 + ventilateur",
 "12759641294":"Ventilateur + thermostat","12759687821":"Thermostat"}
ORD={"Commande formalisée":0,"Pièce déduite":1,"Couvert par la commande":2,"Exclu sur décision":3,
     "Sans pièce":4,"Diagnostic à faire":5}
rows=[]
for x in op:
    v,p=VERDICT.get(x["id"],(None,None))
    if v is None:
        if x["id"] in FR_SYM: v,p=("Couvert par la commande",FR_SYM[x["id"]])
        else: v,p=("Diagnostic à faire","—")
    rows.append((x,v,p))
rows.sort(key=lambda z:(ORD[z[1]],PAYS_FR.get(z[0]["pays"],""),z[0]["prod"] or ""))
r=5
for x,v,p in rows:
    ws.cell(row=r,column=1,value=x["id"]).font=BASE
    ws.cell(row=r,column=2,value=PAYS_FR.get(x["pays"],x["pays"])).font=BOLD
    ws.cell(row=r,column=3,value=x["prod"] or "—").font=BASE
    ws.cell(row=r,column=4,value=x["date"] or "—").font=BASE
    ws.cell(row=r,column=5,value=x["statut"]).font=BASE
    ws.cell(row=r,column=6,value=x["name"][:60]).font=BASE
    ws.cell(row=r,column=7,value=(x["desc"] or "")[:150]).font=BASE
    ws.cell(row=r,column=8,value=v).font=BOLD
    ws.cell(row=r,column=9,value=p).font=BASE
    for cc in range(1,10):
        cell=ws.cell(row=r,column=cc); cell.border=BORD
        cell.alignment=Alignment(wrap_text=(cc in(6,7,9)),vertical="top")
    if v=="Diagnostic à faire": ws.cell(row=r,column=8).fill=WARN
    r+=1
ws.freeze_panes="A5"; ws.auto_filter.ref=f"A4:I{r-1}"
r+=1
ws.cell(row=r,column=1,value="« Diagnostic à faire » = la description ne permet pas d'identifier une pièce (« Box not working correctly », « Box gelée », « Subject »). "
        "Ces lignes ne génèrent pas de commande en l'état.").font=ITAL

# ================= REFERENTIEL =================
ws=wb.create_sheet("Référentiel SKU & prix")
titre(ws,"Référentiel pièces détachées — 294 SKU",
      "Hub technicien croisé avec la base SharePoint de septembre 2022 et la liste d'achat Blupura 2022.")
hdr(ws,4,["SKU BW","Désignation","Machines (hub)","Fournisseur","Réf. fournisseur","Prix cat. (CHF)","Prix achat (EUR)","Remarque"],
    [11,40,34,17,15,14,16,26])
r=5
for d in sorted(ref.values(),key=lambda x:x["ref"]):
    s=d["ref"]; raw=d["prix_catalogue"]
    rem="Prix à demander (AS*)" if raw=="AS*" else ("Absente de la base 2022" if raw=="" and not d["fournisseur"] else "")
    for i,v in enumerate([s,d["designation"],d["machines_hub"],d["fournisseur"],d["ref_fournisseur"],pchf(s),peur(s),rem],1):
        c=ws.cell(row=r,column=i,value=v); c.font=BOLD if i==1 else BASE; c.border=BORD
    for cc in(6,7): ws.cell(row=r,column=cc).number_format=MONEY
    if rem: ws.cell(row=r,column=8).fill=WARN
    r+=1
ws.freeze_panes="A5"; ws.auto_filter.ref=f"A4:H{r-1}"

for s in wb.worksheets:
    if s.title not in ("Référentiel SKU & prix","Vérification claims"): s.sheet_view.showGridLines=False
wb.save(OUT); print("OK",OUT)
