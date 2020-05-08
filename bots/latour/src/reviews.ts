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

        console.log(`assinging PR to to ${reviewers[reviewer]}`)
        console.log(result)
    }
}

export async function fixTitle(context: Context): Promise<void> {
    const pr = context.payload.pull_request
    const repo = context.payload.repository

    const repoRegex: RegExp = /^(?<mat>algo2|orga|sisop)_[0-9]{4}[ab](?:_g([^_]+))?_(?<name>.+)/
    const goodTitle: RegExp = /^\[(?:algo2|orga|sisop)\] [a-z0-9]+ (?<guion>.) \S+$/
    const looseTitle: RegExp = /^(?:\[\w+\] *)?(?<tp>\w+)(?:(?: *\W+ *)?(?<name>\S+))?/

    const repoMatch = repoRegex.exec(repo.name)
    const titleGood = goodTitle.exec(pr.title)
    const titleBad = looseTitle.exec(pr.title)

    let mat = null
    let lab = null
    let name = null
    let newTitle = null

    if (titleBad) {
        lab = titleBad[1].toLocaleLowerCase()
        name = titleBad[2]
    } else {
        lab = pr.title.toLocaleLowerCase()
    }

    if (repoMatch) {
        mat = repoMatch[1]
        if (name == null || name == undefined)
            name = repoMatch[3][0].toLocaleUpperCase() + repoMatch[3].slice(1)
    }

    if (!titleGood) {
        if (titleBad && repoMatch) {
            newTitle = `[${mat}] ${lab} – ${name}`
            console.log(`found bad title "${pr.title}", replacing with "${newTitle}"`)
        } else if (repoMatch) {
            newTitle = `[${mat}] ${lab} – ${name}`
            console.log(`did not find title, using "${newTitle}"`)
        } else {
            console.log(`${repo.name} did not match`)
        }
    } else if (titleGood[1] == "–") {
        console.log(`"${pr.title}" is good!`)
    } else {
        newTitle = pr.title.replace(titleGood[1], "–")
        console.log(`adjusting dash for "${pr.title}"`)
    }

    if (newTitle) {
        const params = context.issue({title: newTitle})
        const result = await context.github.pulls.update(params)
        console.log(result)
    }
}
