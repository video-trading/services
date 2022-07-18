import { ethers } from "ethers";

export interface Message {
  message: string;
  signature: string;
  address: string;
}

interface HandlerResponse {
  statusCode: number;
  body: string;
}

export function handler({
  message,
  signature,
  address,
}: Message): HandlerResponse {
  try {
    const signedAddress = ethers.utils.verifyMessage(message, signature);
    if (address === signedAddress) {
      return {
        statusCode: 200,
        body: JSON.stringify({
          message: "OK",
          address: address,
          signature: signature,
        }),
      };
    }
  } catch (err) {}

  return {
    statusCode: 403,
    body: JSON.stringify({
      message: "Forbidden",
      address: address,
      signature: signature,
    }),
  };
}

export default {
  async fetch(request: Request): Promise<Response> {
    const message = await request.json<Message>();
    const response = handler(message);

    return new Response(response.body, {
      status: response.statusCode,
      headers: {
        "Content-Type": "application/json",
      }
    });
  },
};
