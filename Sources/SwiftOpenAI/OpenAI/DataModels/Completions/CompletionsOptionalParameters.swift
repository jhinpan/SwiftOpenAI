import Foundation

public struct CompletionsOptionalParameters {
    public let prompt: String
    public let suffix: String?
    public let maxTokens: Int?
    public let temperature: Double?
    public let topP: Double?
    public let n: Int?
    public let logprobs: Int?
    public let echo: Bool?
    public let stop: String?
    public let presencePenalty: Double?
    public let frequencyPenalty: Double?
    public let bestOf: Int?
    public let user: String?

    public init(prompt: String,
                suffix: String = "",
                maxTokens: Int? = 16,
                temperature: Double? = 1.0,
                topP: Double? = 1.0,
                n: Int? = 1,
                logprobs: Int? = nil,
                echo: Bool? = false,
                stop: String? = nil,
                presencePenalty: Double? = 0.0,
                frequencyPenalty: Double? = 0.0,
                bestOf: Int? = 1,
                user: String = "") {
        self.prompt = prompt
        self.suffix = suffix
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.n = n
        self.logprobs = logprobs
        self.echo = echo
        self.stop = stop
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
        self.bestOf = bestOf
        self.user = user
    }
}
