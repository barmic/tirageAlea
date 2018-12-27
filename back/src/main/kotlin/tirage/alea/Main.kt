package tirage.alea

import io.vertx.core.Future
import io.vertx.ext.mail.MailConfig
import io.vertx.ext.mail.MailMessage
import io.vertx.ext.mail.MailResult
import io.vertx.rxjava.core.AbstractVerticle
import io.vertx.rxjava.core.Vertx
import io.vertx.rxjava.ext.mail.MailClient
import io.vertx.rxjava.ext.web.Router
import io.vertx.rxjava.ext.web.RoutingContext
import io.vertx.rxjava.ext.web.handler.BodyHandler
import io.vertx.rxjava.ext.web.handler.StaticHandler
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger
import org.apache.logging.log4j.core.lookup.StrSubstitutor
import rx.Observable
import rx.Single

class Main : AbstractVerticle() {
    private val LOGGER: Logger = LogManager.getLogger()
    private var mailClient: MailClient? = null

    override fun start(startFuture: Future<Void>?) {
        LOGGER.info("Satrting…")
        val webRoot = System.getenv("WEB_ROOT")
        LOGGER.debug("Web root {}", webRoot)

        mailClient = mailClient(vertx)

        val router : Router = Router.router(vertx)
        router.post("/api/tirage").handler(BodyHandler.create()).handler(this::handler)
        router.route("/*").handler(StaticHandler.create()
                .setAllowRootFileSystemAccess(true)
                .setCachingEnabled(true)
                .setDirectoryListing(false)
                .setFilesReadOnly(true)
                .setDefaultContentEncoding("utf-8")
                .setWebRoot(webRoot))

        vertx.createHttpServer()
                .requestHandler(router)
                .rxListen(config().getInteger("http.port", 8080))
                .doOnError { startFuture!!.fail(it.cause) }
                .subscribe { startFuture!!.complete() }
    }

    private fun mailClient(vertx: Vertx) : MailClient {
        val config = MailConfig()

        config.hostname = System.getenv("MAIL_HOST")
        config.port = System.getenv("MAIL_PORT").toInt()
        config.isSsl = System.getenv("MAIL_SSL").toBoolean()
        config.username = System.getenv("MAIL_USER")
        config.password = System.getenv("MAIL_PASSWORD")

        return MailClient.createShared(vertx, config)
    }

    private fun handler(ctx: RoutingContext) {
        val tirage = Tirage(ctx.bodyAsJson)
        LOGGER.info("request {}", tirage)
        val mailSent = tirage(tirage.participants)
                .map { (participant, dest) -> sendMail(participant, dest, tirage.subject, tirage.body).toObservable() }

        Observable.merge(mailSent)
                .doOnError {th -> ctx.response().setStatusCode(500).end(th.message)}
                .doOnCompleted {ctx.response().end()}
                .subscribe()
    }

    private fun tirage(participants : List<Participant>) : List<Pair<Participant, String>> {
        var solution = participants.map { it.name }.shuffled()

        var trying = 10
        while (trying-- > 0 && !acceptable(participants, solution)) {
            solution = solution.shuffled()
        }

        return if (trying > 0) IntRange(0, solution.size - 1).map { participants[it] to solution[it] } else listOf()
    }

    private fun acceptable(participants: List<Participant>, solution: List<String>): Boolean {
        return IntRange(0, solution.size - 1)
                .all { participants[it].name != solution[it] && participants[it].partner != solution[it]}
    }

    private fun sendMail(participant: Participant, dest: String, subjectTemplate: String, bodyTemplate: String): Single<MailResult> {
        val sub = StrSubstitutor(mapOf("destinataire" to dest, "participant" to participant.name))

        val message = MailMessage()
        message.from = System.getenv("MAIL_USER")
        message.to = listOf(participant.mail)
        message.subject = sub.replace(subjectTemplate)
        message.text = sub.replace(bodyTemplate)

        LOGGER.trace("subject {} body {}", message.subject, message.text)
        return mailClient!!.rxSendMail(message)
    }
}
