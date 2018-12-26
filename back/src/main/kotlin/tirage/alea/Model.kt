package tirage.alea

import io.vertx.core.json.JsonObject

data class Tirage(val subject: String, val body: String, val participants: List<Participant>) {
    constructor(json: JsonObject) : this(
            json.getString("subject"),
            json.getString("body"),
            json.getJsonArray("participants").map { Participant(it as JsonObject) })
}

data class Participant(val name: String, val mail: String, val partner: String?) {
    constructor(json: JsonObject) : this(
            json.getString("name"),
            json.getString("mail"),
            json.getString("partner")
    )
}