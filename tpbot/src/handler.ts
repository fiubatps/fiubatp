import { Context } from "probot"

export interface Config {
    reviewers: {[key: string]: string}
}

export async function handlePullRequest(context: Context): Promise<void> {
    const config = (await context.config("fiubatp.yml")) as Config

    if (!config) {
        throw new Error("no se encontró fiubatp.yml")
    }

    const {
        reviewers,
    } = config

    const repo = context.payload.repository
    const key = repo.name

    // TODO: learn better Typescript syntax for dicts.
    if (key in reviewers) {
        const reviewer = reviewers[key]
        const params = context.issue({reviewers: [reviewer]})
        const result = await context.github.pulls.createReviewRequest(params)

        console.log(`assinging PR to to ${reviewers[reviewer]}`)
        console.log(result)
    }
}
