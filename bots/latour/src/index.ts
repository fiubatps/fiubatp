import { Application } from "probot"
import { assignReview } from "./reviews"

export = (app: Application): void => {
    app.on("pull_request.opened", assignReview)
}
