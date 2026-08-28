-- ---------------------------------------------------------------------------
-- 11 — Les pièces posées sur les tickets archivés
--
-- Monday porte une colonne « Spare part name 1 » que la reprise 09 n'avait
-- pas lue : sans elle, le rapport annonce 264 tickets fermés et zéro pièce
-- utilisée. 97 tickets archivés la renseignent, en texte libre.
--
-- Deux partis pris :
--
-- 1. On rattache à une référence du catalogue quand le texte la donne — soit
--    en tête (« BW-0161 HMI Cable Assembly »), soit par une réf fournisseur à
--    six chiffres (« 404008 - VENTILATORE ASSIALE »), y compris l'ancienne
--    numérotation Blupura. Sinon la pièce reste en texte libre : « fun »,
--    « panneau de controle » — c'est ce que le technicien a écrit, on ne
--    devine pas à sa place.
--
-- 2. ordered_manual = true. Ces pièces ont été POSÉES, pas demandées. Sans
--    ce drapeau elles rempliraient « Pièces à commander » de 97 lignes de
--    texte libre incommandables.
--
-- Rejouable : un claim qui porte déjà une pièce est laissé tel quel.
-- ---------------------------------------------------------------------------

with src(monday_id, txt, qty) as (values
  ('5820137528', 'ID961 - thermostat control circuit', 1),
  ('6053362328', 'fan for Piccola box', 1),
  ('6053386043', 'Fan for Piccola box', 1),
  ('6053454768', 'fan for Piccola box', 1),
  ('6594506046', 'Thermostat', 1),
  ('6717341204', 'ventilateur + boitier DTI', 1),
  ('7205899542', 'fun', 1),
  ('7204775419', 'fun', 1),
  ('6594615228', 'Level controller', 2),
  ('7312922910', 'Face PRO2 white', 1),
  ('7453009828', 'solenoid valve', 1),
  ('7406866441', 'solenoid valve', 1),
  ('7350524494', 'AC ADAPTOR', 1),
  ('7408247356', 'pump for sparkling water', 1),
  ('6652393754', 'FAN', 1),
  ('6926986447', 'recirculation pump', 1),
  ('7676729116', 'Fun for piccola box', 1),
  ('7961999124', 'connector', 1),
  ('7988965516', 'Controller ID961', 1),
  ('7998774631', 'Submersible Pump AP-333', 1),
  ('8029261190', 'transformer 174391', 1),
  ('8035828137', 'Transformer 174391', 1),
  ('8046028953', 'Controller ID961', 1),
  ('8067234822', 'Level sensor cable', 1),
  ('8091536012', 'BW-0161 HMI Cable Assembly', 1),
  ('8067077085', '174391 - 230v/24vdc 1.5A Power Adapter (Type A)', 1),
  ('8028904034', 'Controller ID 961', 1),
  ('8187941275', 'BW-0162 Box Cable assembly', 1),
  ('8199089069', 'BW-0162 PRO1 - Connection box side', 1),
  ('7683525515', 'fan box 30 B&O -DR200A', 1),
  ('8187966671', 'BW-0167 Controller 30 - A', 1),
  ('7586218216', 'Eliwell ID961', 1),
  ('8309326614', 'compressor start coil', 1),
  ('8317241229', 'SPARE LEVEL CONTROL PLUS AMBIENT, COLD AND FIZZ', 1),
  ('7824562643', 'Fun', 1),
  ('8297023064', 'Controller 30 - A', 1),
  ('8199036172', 'door base cabinet', 1),
  ('8287973831', 'PCB upgrade', 1),
  ('8350926714', 'PCB upgrade', 1),
  ('8189910526', 'SCHEDA CARBONATORE+TIME OUT - LIV-I', 1),
  ('8384651123', '404008 - VENTILATORE ASSIALE 120X120X25', 1),
  ('8405854777', '404008 VENTILATORE ASSIALE 120X120X25', 2),
  ('7998603909', 'fun', 1),
  ('7963971542', 'connecteur', 1),
  ('5733136602', 'blupura box 80 - replacement', 1),
  ('7812645279', 'fun', 1),
  ('8008932426', 'Recirculation pump', 1),
  ('8912463226', '701148', 15),
  ('8911872185', '174391 - power supply', 1),
  ('8794034772', 'recirculation pump', 1),
  ('8787235450', 'VENTILATORE ASSIALE 120X120X25 - 404008', 1),
  ('8667085337', 'SPARE AGITATOR - RECIRCULATION PUMP 230V', 1),
  ('8516784300', 'Controller 30 - A', 1),
  ('8914119792', 'grille', 1),
  ('5978826798', 'Support de la gear-box', 1),
  ('7518489655', 'Sparkling water button', 1),
  ('8838469512', 'BW-0191 fun', 1),
  ('8505387611', 'SPARE BLUGLASS TOWER TAP ELECTRONIC BOARD - 150576', 1),
  ('8371148930', 'SPARE LEVEL CONTROL DC 230V', 1),
  ('9237144416', 'PCB upgrade', 3),
  ('8482498890', 'SPARE PUSH BUTTON STILL LITTLE', 1),
  ('9077238203', 'SPARE LEVEL CONTROL DC 230V W/RETROFIT CABLE', 1),
  ('8406165332', 'transformer', 1),
  ('8516850556', 'Controller 30 - A', 1),
  ('8362425959', 'Controller 30 - A', 1),
  ('8309569585', 'Controller 30 - A', 1),
  ('12333350408', 'Carte éléctronique', 1),
  ('12347810239', 'panneau de controle', 1),
  ('12368844623', 'panneau de controle', 1),
  ('12527446190', 'panneau de controle', 1),
  ('12201994621', 'panneau de controle', 1),
  ('12609085420', 'Transformateur 230V', 1),
  ('12670167721', 'Carte électronique + panneau de controle', 2),
  ('12670223767', 'Carte électronique + panneau de controle', 2),
  ('12670519576', 'Carte électronique + panneau de controle', 2),
  ('12699759604', 'Transformateur 230V', 1),
  ('12771717012', 'Transformateur 230V', 1),
  ('12429326796', 'Thermostat', 1),
  ('12464080297', 'Transformateur 230V', 1),
  ('2964294740', 'BW-0173 Flow compensator 8mm', 1),
  ('4819384609', 'main board', 1),
  ('4548713633', 'BW-0177 BAR1 Tap outlet', 1),
  ('5452392120', 'Installation kit', 1),
  ('5167330011', 'Gearbox REV 01', 1),
  ('5166482922', 'Gearbox AQTIV ONE (Rev1)', 1),
  ('5222626763', 'Water inlet connector', 1),
  ('6592352647', 'Bw 050', 1),
  ('6426163431', 'Gear rev 2', 1),
  ('6539695550', 'Gear rev 2', 1),
  ('6397823134', 'Gear rev 2', 1),
  ('12771969839', 'ventilateur', 1),
  ('12841349698', 'ventilateur', 1),
  ('12487631648', 'piston', 1),
  ('12851840644', 'ventilateur', 1),
  ('12793906408', 'carte electronique', 1),
  ('12889961878', 'ventilateur', 1),
  ('12891175711', 'ventilateur', 1)
)
insert into public.claim_parts (claim_id, part_ref, free_text, qty, ordered_manual)
select c.id, m.ref, src.txt, greatest(1, least(999, src.qty)), true
  from src
  join public.claims c on c.monday_id = src.monday_id
  left join lateral (
    select pt.ref
      from public.parts pt
     where pt.ref = upper(substring(src.txt from '^\s*(BW-[0-9]{4})'))
        or pt.supplier_ref = substring(src.txt from '([0-9]{6})')
        or pt.supplier_ref_legacy = substring(src.txt from '([0-9]{6})')
     -- la réf interne prime sur la réf fournisseur, moins sûre
     order by (pt.ref = upper(substring(src.txt from '^\s*(BW-[0-9]{4})'))) desc, pt.ref
     limit 1
  ) m on true
 where not exists (select 1 from public.claim_parts cp where cp.claim_id = c.id);

-- Contrôle : ce qui a été rattaché au catalogue, et ce qui reste en texte libre.
select count(*) filter (where part_ref is not null) as rattachees_au_catalogue,
       count(*) filter (where part_ref is null)     as en_texte_libre,
       count(*)                                     as total
  from public.claim_parts where ordered_manual and order_id is null;

-- Ce que le rapport pourra montrer : les tickets fermés qui portent une pièce.
select count(distinct c.id) as tickets_fermes_avec_pieces
  from public.claims c
  join public.claim_parts cp on cp.claim_id = c.id
 where c.status in ('Repaired and restocked', 'Spare Parts (Bin)');
