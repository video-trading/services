import { getParserByLanguage } from "@etherdata-blockchain/codeblock";

export interface Message {
  code: string;
  language: string;
}

interface HandlerResponse {
  statusCode: number;
  body: string;
}

export function handler({ code, language }: Message): HandlerResponse {
  try {
    const parser = getParserByLanguage(language);
    const blocks = parser.parse(code);
    const generatedCode = parser.generate(blocks);

    const data = {
      blocks,
      code: generatedCode,
    };

    return {
      statusCode: 200,
      body: JSON.stringify(data),
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
