import { ethers } from "ethers";
import jwt from "@tsndr/cloudflare-worker-jwt";

export interface Message {
  message: string;
  signature: string;
  address: string;
}

interface JWTPayload {
  userId: string;
}

interface HandlerResponse {
  statusCode: number;
  body: string;
}

export async function handler({
  message,
  signature,
  address,
}: Message): Promise<HandlerResponse> {
  try {
    const signedAddress = ethers.utils.verifyMessage(message, signature);
    if (address === signedAddress) {
      let password = process.env.PASSWORD!;
      const payload: JWTPayload = {
        userId: address,
      };
      let token = await jwt.sign(payload, password);
      return {
        statusCode: 200,
        body: JSON.stringify({
          message: "OK",
          accessToken: token,
        }),
      };
    }
  } catch (err) {}

  return {
    statusCode: 403,
    body: JSON.stringify({
      message: "Forbidden",
    }),
  };
}

export default {
  async fetch(request: Request): Promise<Response> {
    const message = await request.json<Message>();
    const response = await handler(message);

    return new Response(response.body, {
      status: response.statusCode,
      headers: {
        "Content-Type": "application/json",
      },
    });
  },
};
