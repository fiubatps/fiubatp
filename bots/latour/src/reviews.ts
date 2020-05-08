import { Context } from "probot"

export interface Config {
    reviewers: { [key: string]: string }
}

export async function assignReview(context: Context): Promise<void> {
    const file = "pullreq.yml"
    const config = (await context.config(file)) as Config

    if (!config) {
        throw new Error(`no se encontró ${file}`)
    }

    const { reviewers } = config

    const repo = context.payload.repository
    const key = repo.name

    // TODO: learn better Typescript syntax for dicts.
    if (key in reviewers) {
        const reviewer = reviewers[key]
        const params = context.issue({ reviewers: [reviewer] })
        const result = await context.github.pulls.createReviewRequest(params)

        console.log(`assinging PR to to ${reviewer}`)
        console.log(result)
    }
}

export async function fixTitle(context: Context): Promise<void> {
    const pr = context.payload.pull_request
    const repo = context.payload.repository

    // Comprobar que es un repo de entregas, y extraer metadata.
    const repoRegex: RegExp = /^(?<mat>algo2|orga|sisop)_[0-9]{4}[ab](?:_g([^_]+))?_(?<name>.+)/
    const repoMatch = repoRegex.exec(repo.name)

    if (!repoMatch) {
        console.log(`fixTitle: ignoring ${repo.name}`)
        return
    }

    let materia = repoMatch[1]
    let apellido = repoMatch[3][0].toLocaleUpperCase() + repoMatch[3].slice(1)
    let newTitle = null

    //  Comprobar si el título ya es correcto, o solo difiere en puntuación.
    // Si no es correcto, aplicar una expresión regular para más o menos extraer
    // el nombre de la entrega, y (si lo hay) el apellido.
    const goodTitle: RegExp = /^\[(?:algo2|orga|sisop)\] [a-z0-9]+ (?<guion>.) \S+$/
    const looseTitle: RegExp = /^(?:\[\w+\] *)?(?<tp>\w+)(?:(?: *\W+ *)?(?<name>\S+))?/
    const titleGood = goodTitle.exec(pr.title)
    const titleBad = looseTitle.exec(pr.title)

    if (titleGood) {
        if (titleGood[1] == "–") {
            console.log(`"${pr.title}" is good!`)
        } else {
            newTitle = pr.title.replace(titleGood[1], "–")
            console.log(`adjusting dash for "${pr.title}"`)
        }
    } else if (titleBad) {
        if (titleBad[2] != undefined) {
            apellido = titleBad[2]
        }
        const lab = titleBad[1].toLocaleLowerCase()
        newTitle = `[${materia}] ${lab} – ${apellido}`
        console.log(
            `found bad title "${pr.title}", replacing with "${newTitle}"`
        )
    } else if (!pr.title.includes(" ")) {
        const lab = pr.title.toLocaleLowerCase()
        newTitle = `[${materia}] ${lab} – ${apellido}`
        console.log(`could not parse "${pr.title}", using "${newTitle}"`)
    } else {
        console.log(
            `could not parse multi-word "${pr.title}", refraining from action`
        )
    }

    if (newTitle) {
        const params = context.issue({ title: newTitle })
        const result = await context.github.pulls.update(params)
        console.log(result)
    }
}
