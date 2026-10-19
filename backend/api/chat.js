
export default async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ error: "Method not allowed" });
  }

  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey) {
    return res.status(500).json({
      error: "The AI service is not configured yet."
    });
  }

  try {
    const { message, model = "gpt-6-luna" } = req.body ?? {};

    if (typeof message !== "string" || !message.trim()) {
      return res.status(400).json({
        error: "A non-empty message is required."
      });
    }

    if (message.length > 12000) {
      return res.status(400).json({
        error: "Message is too long."
      });
    }

    // Only allow the initial low-cost model until we add
    // a server-side model registry and manual model selection.
    if (model !== "gpt-6-luna") {
      return res.status(400).json({
        error: "This model is not enabled yet."
      });
    }

    const response = await fetch(
      "https://api.openai.com/v1/responses",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model,
          instructions:
            "You are Akari, a friendly, thoughtful AI companion. " +
            "Reply naturally and clearly. Do not claim to have " +
            "performed actions you have not performed.",
          input: message,
          max_output_tokens: 500
        }),
        signal: AbortSignal.timeout(30000)
      }
    );

    const data = await response.json();

    if (!response.ok) {
      console.error("OpenAI API error:", response.status);
      return res.status(502).json({
        error: "The AI provider could not complete the request."
      });
    }

    const reply = (data.output ?? [])
      .filter(item => item.type === "message")
      .flatMap(item => item.content ?? [])
      .filter(item => item.type === "output_text")
      .map(item => item.text)
      .join("\n")
      .trim();

    if (!reply) {
      return res.status(502).json({
        error: "The AI provider returned an empty reply."
      });
    }

    return res.status(200).json({ reply });
  } catch (error) {
    console.error("Chat request failed:", error.name);
    return res.status(502).json({
      error: "Could not reach the AI provider. Please try again."
    });
  }
}
