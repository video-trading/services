import { handler, Message } from ".";

describe("Given a handler", () => {
  test("When parsing succeed", async () => {
    const code = `
    //@codeblock
    string a = "a"`;

    const message: Message = {
      code: code,
      mode: "parsing",
      language: "sol",
    };
    const result = handler(message);
    const data = JSON.parse(result.body);
    expect(data.blocks.length).toBe(2);
  });

  test("When generation succeed", async () => {
    const code = `
    //@codeblock
    string a = "a"`;

    const message: Message = {
      blocks: [],
      mode: "generation",
      language: "sol",
    };
    const result = handler(message);
    const data = JSON.parse(result.body);
    expect(data.code).toBeDefined();
  });

  test("When failed", async () => {
    const code = `
    //@codeblock
    string a = "a"`;

    const message: Message = {
      blocks: [],
      //@ts-ignore
      mode: "a",
      language: "sol",
    };
    const result = handler(message);
    expect(result.statusCode).toBe(400);
  });

  test("When parsing failed", async () => {
    const code = `
    //@codeblock
    string a = "a"`;

    const message: Message = {
      code: code,
      mode: "parsing",
      language: "python",
    };
    const result = handler(message);
    expect(result.statusCode).toBe(500);
    expect(result.body).toBe(
      JSON.stringify({
        message: "Error: Language python not supported",
      })
    );
  });
});
