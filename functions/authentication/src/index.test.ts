import { handler, Message } from ".";
import { ethers } from "ethers";

describe("Given a handler", () => {
  test("When authentication failed", () => {
    const message: Message = {
      message: "Hello World",
      signature: "0x",
      address: "0x0000000000000000000000000000000000000000",
    };
    const response = handler(message);
    expect(response.statusCode).toBe(403);
  });

  test("When authentication succeeded", async () => {
    const textMessage = "hello world";
    const wallet = ethers.Wallet.createRandom({});
    const signature = await wallet.signMessage(textMessage);

    const message: Message = {
      message: textMessage,
      signature: signature,
      address: wallet.address,
    };
    const response = handler(message);
    expect(response.statusCode).toBe(200);
  });

  test("When authentication failed", async () => {
    const textMessage = "hello world";
    const wallet = ethers.Wallet.createRandom({});
    const signature = await wallet.signMessage(textMessage);

    const message: Message = {
      message: "",
      signature: signature,
      address: wallet.address,
    };
    const response = handler(message);
    expect(response.statusCode).toBe(403);
  });
});
