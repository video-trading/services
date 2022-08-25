import { handler, Message } from ".";

describe("Given a handler", () => {
  test("When generation succeed", async () => {
    const code = `
    //@codeblock
    string a = "a"`;

    const message: Message = {
      code: code,
      language: "sol",
    };
    const result = handler(message);
    const data = JSON.parse(result.body);
    expect(data.blocks.length).toBe(2);
  });

  test("When generation failed", async () => {
    const code = `
    //@codeblock
    string a = "a"`;

    const message: Message = {
      code: code,
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
