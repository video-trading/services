import {
  CodeBlock,
  getParserByLanguage,
} from "@etherdata-blockchain/codeblock";

export interface Message {
  code?: string;
  blocks?: CodeBlock<any>[];
  language: string;
  mode: "generation" | "parsing";
}

interface HandlerResponse {
  statusCode: number;
  body: string;
}

export function handler({
  code,
  language,
  mode,
  blocks,
}: Message): HandlerResponse {
  try {
    const parser = getParserByLanguage(language);
    if (mode === "parsing") {
      const blocks = parser.parse(code!);

      const data = {
        blocks,
      };

      return {
        statusCode: 200,
        body: JSON.stringify(data),
      };
    }

    if (mode === "generation") {
      const code = parser.generate(blocks!);

      const data = {
        code,
      };

      return {
        statusCode: 200,
        body: JSON.stringify(data),
      };
    }

    return {
      statusCode: 400,
      body: JSON.stringify({
        message: "Error: mode not supported",
      }),
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: `${err}`,
      }),
    };
  }
}

export default {
  async fetch(request: Request): Promise<Response> {
    const message = await request.json<Message>();
    const response = handler(message);

    return new Response(response.body, {
      status: response.statusCode,
      headers: {
        "Content-Type": "application/json",
      },
    });
  },
};
