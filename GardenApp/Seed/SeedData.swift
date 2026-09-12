import Foundation
import SwiftData

/// Populates first-launch data: the two MapAreas (garden + greenhouse), the
/// Greenhouse structure placed on the garden map, a starter plant/tree
/// catalog for the wiki, and a set of monthly tasks. Runs once — checks for
/// existing data before inserting anything, so it's safe to call on every
/// launch.
///
/// This app is focused on Sweden: planting/harvest months and tasks below
/// assume a typical central/southern Swedish climate (roughly odlingszon
/// II-III — Svealand). If your garden is further north or south, edit the
/// months on each wiki entry — see docs/decisions/0007-sweden-focus.md.
enum SeedData {
    static func populateIfNeeded(in context: ModelContext) {
        seedMapAreasAndStructuresIfNeeded(in: context)
        seedSpeciesIfNeeded(in: context)
        seedTasksIfNeeded(in: context)
        try? context.save()
    }

    private static func seedMapAreasAndStructuresIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<MapArea>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let garden = MapArea(name: "Garden", kind: .outdoor, columns: 10, rows: 14)
        let greenhouse = MapArea(name: "Greenhouse", kind: .greenhouse, columns: 6, rows: 8)
        context.insert(garden)
        context.insert(greenhouse)

        // Placed near a corner of the garden so it doesn't overlap the
        // default empty space where beds usually go.
        let greenhouseStructure = Structure(
            name: "Greenhouse",
            x: 7,
            y: 0,
            width: 3,
            height: 3,
            colorHex: "#6B8CA3",
            symbolName: "house.fill",
            mapArea: garden,
            linkedMapArea: greenhouse
        )
        context.insert(greenhouseStructure)
    }

    private static func seedSpeciesIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<PlantSpecies>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for species in starterSpecies {
            context.insert(species)
        }
    }

    private static func seedTasksIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<MonthlyTaskTemplate>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for task in starterTasks {
            context.insert(task)
        }
    }

    /// Common plants and trees found in Swedish home gardens, with
    /// planting/harvest months tuned to a typical central/southern Swedish
    /// growing season (short summers, frost risk into mid/late May).
    private static var starterSpecies: [PlantSpecies] {
        [
            PlantSpecies(
                commonName: "Potatis",
                scientificName: "Solanum tuberosum",
                category: .vegetable,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Förgro (chitta) i ljus och svalt läge från februari. Kupa jord runt stjälkarna när de växer för att skydda mot grönfärgning.",
                soilNotes: "Lucker, väldränerad jord.",
                spacingNotes: "30-40cm mellan plantor.",
                plantingMonths: [5],
                harvestMonths: [8, 9],
                symbolName: "carrot.fill",
                colorHex: "#B08968"
            ),
            PlantSpecies(
                commonName: "Morot",
                scientificName: "Daucus carota",
                category: .vegetable,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Gallra groddplantorna så att rötterna får plats. Håll jorden jämnt fuktig för raka morötter.",
                soilNotes: "Lucker, stenfri jord så rötterna växer raka.",
                spacingNotes: "Gallra till 5-8cm mellan plantor.",
                plantingMonths: [5, 6],
                harvestMonths: [8, 9, 10],
                symbolName: "carrot.fill",
                colorHex: "#E8823C"
            ),
            PlantSpecies(
                commonName: "Rabarber",
                scientificName: "Rheum rhabarbarum",
                category: .vegetable,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Flerårig — sätts en gång och står kvar i många år. Undvik att skörda för hårt första året efter plantering.",
                soilNotes: "Näringsrik, väldränerad jord med mycket kompost.",
                spacingNotes: "1m mellan plantor, den breder ut sig.",
                plantingMonths: [4, 5],
                harvestMonths: [5, 6, 7],
                symbolName: "leaf.fill",
                colorHex: "#C23C4C"
            ),
            PlantSpecies(
                commonName: "Dill",
                scientificName: "Anethum graveolens",
                category: .herb,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Självsår lätt om den får gå i blom. Så om varannan vecka under sommaren för jämn tillgång.",
                soilNotes: "Näringsrik, väldränerad jord.",
                spacingNotes: "20cm mellan plantor.",
                plantingMonths: [5, 6],
                harvestMonths: [7, 8],
                symbolName: "leaf.fill",
                colorHex: "#4E7A3D"
            ),
            PlantSpecies(
                commonName: "Gräslök",
                scientificName: "Allium schoenoprasum",
                category: .herb,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Flerårig. Klipp ner efter blomning för nya, mjuka blad. Går bra att dela och flytta på våren.",
                soilNotes: "Näringsrik, fuktighetshållande jord.",
                spacingNotes: "15-20cm mellan tuvor.",
                plantingMonths: [4, 5],
                harvestMonths: [5, 6, 7, 8, 9],
                symbolName: "leaf.fill",
                colorHex: "#5C7A5C"
            ),
            PlantSpecies(
                commonName: "Persilja",
                scientificName: "Petroselinum crispum",
                category: .herb,
                sunRequirement: .partialSun,
                waterRequirement: .medium,
                careNotes: "Tvåårig men odlas oftast som ettårig. Förgro gärna inomhus i april för tidigare skörd.",
                soilNotes: "Näringsrik, väldränerad jord.",
                spacingNotes: "20cm mellan plantor.",
                plantingMonths: [5],
                harvestMonths: [7, 8, 9],
                symbolName: "leaf.fill",
                colorHex: "#4E9A4E"
            ),
            PlantSpecies(
                commonName: "Jordgubbe",
                scientificName: "Fragaria × ananassa",
                category: .fruit,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Täck med halm så bären hålls rena. Ta bort revor om du inte vill föröka, byt ut plantor efter 3-4 år.",
                soilNotes: "Näringsrik, något sur, väldränerad jord.",
                spacingNotes: "30cm mellan plantor.",
                plantingMonths: [5, 8],
                harvestMonths: [7],
                symbolName: "circle.fill",
                colorHex: "#C23C4C"
            ),
            PlantSpecies(
                commonName: "Svarta vinbär",
                scientificName: "Ribes nigrum",
                category: .fruit,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Beskär äldre grenar vid basen på vintern för att ge plats åt nya skott. Gödsla på våren.",
                soilNotes: "Näringsrik, fuktighetshållande jord.",
                spacingNotes: "1.2-1.5m mellan buskar.",
                plantingMonths: [4, 10],
                harvestMonths: [7, 8],
                symbolName: "circle.fill",
                colorHex: "#3E3E5C"
            ),
            PlantSpecies(
                commonName: "Krusbär",
                scientificName: "Ribes uva-crispa",
                category: .fruit,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Tåligt buske, klarar halvskugga. Beskär för öppen krona så luft kan cirkulera och minska mjöldagg.",
                soilNotes: "Väldränerad, näringsrik jord.",
                spacingNotes: "1.2m mellan buskar.",
                plantingMonths: [4, 10],
                harvestMonths: [7, 8],
                symbolName: "circle.fill",
                colorHex: "#7A9A4E"
            ),
            PlantSpecies(
                commonName: "Äppelträd",
                scientificName: "Malus domestica",
                category: .tree,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                isTree: true,
                careNotes: "Beskär i slutet av vintern (feb-mars) innan save börjar stiga. Gallra frukt i juni för större äpplen. Många svenska sorter behöver en pollinatörssort i närheten.",
                soilNotes: "Djup, väldränerad, näringsrik jord.",
                spacingNotes: "3-5m mellan träd beroende på grundstam.",
                plantingMonths: [4, 10],
                harvestMonths: [9, 10],
                symbolName: "tree.fill",
                colorHex: "#6B8E4E"
            ),
            PlantSpecies(
                commonName: "Plommonträd",
                scientificName: "Prunus domestica",
                category: .tree,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                isTree: true,
                careNotes: "Beskär på sommaren, inte på vintern, för att undvika silverbladssjuka. Behöver ett skyddat, varmt läge i svenskt klimat.",
                soilNotes: "Väldränerad, något kalkhaltig jord.",
                spacingNotes: "4m mellan träd.",
                plantingMonths: [4, 10],
                harvestMonths: [8, 9],
                symbolName: "tree.fill",
                colorHex: "#7A3E5C"
            ),
            PlantSpecies(
                commonName: "Syrén",
                scientificName: "Syringa vulgaris",
                category: .shrub,
                sunRequirement: .fullSun,
                waterRequirement: .low,
                careNotes: "Mycket vinterhärdig klassiker i svenska trädgårdar. Beskär direkt efter blomning, annars riskerar du att klippa bort nästa års blomknoppar.",
                soilNotes: "Varierar, klarar de flesta jordar om det är väldränerat.",
                spacingNotes: "2-3m mellan buskar om de ska bilda häck.",
                plantingMonths: [4, 9],
                harvestMonths: [5, 6],
                symbolName: "tree",
                colorHex: "#8B7CC2"
            ),
            PlantSpecies(
                commonName: "Tulpan",
                scientificName: "Tulipa",
                category: .flower,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Plantera lökar på hösten innan marken tjälar. Låt bladen vissna ner naturligt efter blomning innan du klipper bort dem.",
                soilNotes: "Väldränerad jord — lökar ruttnar i stillastående vatten.",
                spacingNotes: "10-15cm mellan lökar, planteras 15-20cm djupt.",
                plantingMonths: [9, 10],
                harvestMonths: [5],
                symbolName: "camera.macro",
                colorHex: "#C24C8C"
            ),
            PlantSpecies(
                commonName: "Pion",
                scientificName: "Paeonia",
                category: .flower,
                sunRequirement: .fullSun,
                waterRequirement: .medium,
                careNotes: "Flerårig och mycket långlivad — ogillar att flyttas. Plantera inte ögonen (knopparna) för djupt, annars blommar den sämre.",
                soilNotes: "Näringsrik, väldränerad jord.",
                spacingNotes: "60-90cm mellan plantor.",
                plantingMonths: [9],
                harvestMonths: [6],
                symbolName: "camera.macro",
                colorHex: "#D9518C"
            )
        ]
    }

    /// Generic gardening tasks timed for a typical central/southern Swedish
    /// growing season — short summers, frost risk lingering into May, and a
    /// long dormant season where the greenhouse matters most.
    private static var starterTasks: [MonthlyTaskTemplate] {
        [
            (1, "Planera odlingsåret", "Beställ frön tidigt — populära svenska sorter kan ta slut redan i februari. Gå igenom wikin för inspiration.", TaskCategory.other),
            (1, "Kontrollera lagrad potatis och lökar", "Se till att inget ruttnar eller torkar ut i källaren under vintern.", .cleanup),
            (2, "Förgro potatis", "Ställ utsädespotatis ljust och svalt för att chitta inför majplanteringen.", .planting),
            (2, "Beskär fruktträd", "Beskär äpple och plommon medan de fortfarande är vintervila, gärna innan savningen startar i mars.", .pruning),
            (3, "Sådd inomhus", "Starta tomater, paprika och andra långodlade grödor inomhus eller i växthuset med gro-ljus.", .greenhouse),
            (3, "Service av växthuset", "Rengör växthusets glas/skivor och kontrollera värmekällan innan säsongen drar igång.", .greenhouse),
            (4, "Förbered rabatterna", "Jobba in kompost när jorden har tinat och gå att bearbeta.", .fertilizing),
            (4, "Plantera bärbuskar", "Plantera vinbär, krusbär och rabarber på barrot medan de fortfarande är i vila.", .planting),
            (5, "Bevaka nattfrosten", "Nattfrost förekommer fortfarande in i maj i stora delar av Sverige — vänta med känsliga plantor tills risken är över.", .other),
            (5, "Härda av och plantera ut", "Flytta ut växthusuppstartade tomater, gurka och paprika när frostrisken är över.", .planting),
            (6, "Direktsådd utomhus", "Morötter, dill och andra snabba grödor gynnas av de långa junidagarna.", .planting),
            (6, "Vattna under midsommar", "De långa ljusa timmarna ger snabb tillväxt — vattna nyplanterat rejält.", .watering),
            (7, "Skörda sommarens bär", "Jordgubbar, vinbär och krusbär mognar vanligen under juli.", .harvesting),
            (7, "Knip av och binda upp", "Håll tomater och blommor i schack under högsäsongens tillväxt.", .pruning),
            (8, "Skörda och konservera", "Potatis, bär och örter är redo — frys eller syrsalta inför vintern, en klassisk svensk tradition.", .harvesting),
            (8, "Så en andra omgång snabbväxande grödor", "Sallat och rädisor för en sen skörd innan nätterna blir kalla.", .planting),
            (9, "Ta in växthusgrödorna", "Plocka eller flytta in tomater och paprika innan nätterna blir för kalla.", .harvesting),
            (9, "Plantera vårlökar", "Tulpaner, pioner och andra vårblommande lökar/knölar sätts när jorden svalnat.", .planting),
            (10, "Plantera fruktträd", "Barrotsplantering av äppel- och plommonträd på hösten innan marken tjälar.", .planting),
            (10, "Städa och täck rabatterna", "Rensa bort sommarens uttjänta grödor och täck perenner inför frosten.", .cleanup),
            (11, "Skydda känsliga plantor", "Flytta krukväxter in i växthuset eller ett frostfritt läge när de första hårda frostnätterna kommer.", .greenhouse),
            (11, "Isolera växthuset", "Sätt in extra isolering eller en frostvakt inför de kallaste månaderna.", .greenhouse),
            (12, "Sammanfatta året", "Anteckna vad som gick bra och uppdatera wikin inför nästa säsong.", .other),
            (12, "Kolla övervintrande plantor", "Se till att inget i växthuset har frusit sönder eller torkat ut.", .other)
        ].map { month, title, details, category in
            MonthlyTaskTemplate(month: month, title: title, details: details, category: category, isBuiltIn: true)
        }
    }
}
