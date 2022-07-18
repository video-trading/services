import * as crypto from "crypto";

//@ts-ignore
global.crypto = {
  subtle: crypto.webcrypto.subtle,
};
