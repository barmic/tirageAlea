package tirage.alea

import io.vertx.core.Future
import io.vertx.core.Handler
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
import java.util.stream.IntStream

class Main : AbstractVerticle() {
    private val LOGGER: Logger = LogManager.getLogger()
    private var mailClient: MailClient? = null

    override fun start(startFuture: Future<Void>?) {
        LOGGER.info("Satrting…")

        mailClient = mailClient(vertx)

        val router : Router = Router.router(vertx)
        router.post("/api*").handler(BodyHandler.create())
        router.post("/api/tirage").handler(this::handler)
        val webRoot = "/home/michel/Projects/Perso/tirage/front/dist"
        router.route("/*").handler(StaticHandler.create().setAllowRootFileSystemAccess(true).setWebRoot(webRoot))

        vertx.createHttpServer()
                .requestHandler(router)
                .rxListen(config().getInteger("http.port", 8080))
                .doOnError { startFuture?.fail(it.cause) }
                .subscribe { startFuture?.complete() }
    }

    private fun mailClient(vertx: Vertx) : MailClient {
        val config = MailConfig().setSsl(true)
        config.hostname = System.getenv("MAIL_HOST")
        config.username = System.getenv("MAIL_USER")
        config.password = System.getenv("MAIL_PASSWORD")
//        envInt("MAIL_PORT").ifPresent(config::setPort);

        return MailClient.createShared(vertx, config)
    }

    private fun handler(ctx: RoutingContext) {
        val tirage = Tirage(ctx.bodyAsJson)
        LOGGER.info("request {}", tirage)
        var mailSent = tirage(tirage.participants)
                .map { (participant, dest) -> sendMail(participant, dest, tirage.subject, tirage.body).toCompletable() }

        Observable.from(mailSent).subscribe({ctx.response().end()}, {th -> ctx.response().setStatusCode(500).end(th.message)})
    }

    private fun tirage(participants : List<Participant>) : List<Pair<Participant, String>> {
        var solution = participants.map { it.name }.shuffled()

        while (!acceptable(participants, solution)) {
            solution = solution.shuffled()
        }

        return IntRange(0, solution.size - 1).map { participants[it] to solution[it] }
    }

    private fun acceptable(participants: List<Participant>, solution: List<String>): Boolean {
        return IntStream.range(0, solution.size).allMatch {participants[it].name != solution[it] && participants[it].partner != solution[it]}
    }

    private fun sendMail(participant: Participant, dest: String, subjectTemplate: String, bodyTemplate: String): Single<MailResult> {
        val sub = StrSubstitutor(mapOf("destinataire" to dest, "participant" to participant.name))

        val message = MailMessage()
        message.from = "fromUser"
        message.to = listOf(participant.mail)
        message.subject = sub.replace(subjectTemplate)
        message.text = sub.replace(bodyTemplate)

        LOGGER.info("subject {} body {}", message.subject, message.text)
        return mailClient!!.rxSendMail(message)
    }
}
