require "secure_random"
require "./lib_sodium"

module Sodium
  module SecretBox
    extend self

    KEY_BYTES = 32u8
    NONCE_BYTES = 24u8
    ZERO_BYTES = 32u8
    BOX_ZERO_BYTES = 16u8

    def sanity_check
      unless KEY_BYTES == LibSodium.crypto_secretbox_keybytes &&
             NONCE_BYTES == LibSodium.crypto_secretbox_noncebytes &&
             ZERO_BYTES == LibSodium.crypto_secretbox_zerobytes &&
             BOX_ZERO_BYTES == LibSodium.crypto_secretbox_boxzerobytes
        raise "Sanity check failed!"
      end
    end

    def encrypt(message : Bytes, key : Bytes)
      validate_key(key)
      padded_message_length = message.size + ZERO_BYTES
      padded_message = Bytes.new(padded_message_length)
      message.copy_to padded_message + ZERO_BYTES
      nonce = SecureRandom.random_bytes(NONCE_BYTES)
      ciphertext = Bytes.new(padded_message.size)
      LibSodium.crypto_secretbox(ciphertext, padded_message, padded_message.size, nonce, key)
      return ciphertext, nonce
    end

    def decrypt(cipher_nonce : Tuple(Bytes, Bytes), key)
      decrypt(cipher_nonce[0], cipher_nonce[1], key)
    end
    
    def decrypt(ciphertext : Bytes, nonce : Bytes, key : Bytes)
      validate_key(key)
      validate_nonce(nonce)
      raise ArgumentError.new("Invalid ciphertext") unless ciphertext[0, BOX_ZERO_BYTES].all?{|b| b == 0}
      message = Bytes.new(ciphertext.size)
      LibSodium.crypto_secretbox_open(message, ciphertext, ciphertext.size, nonce, key)
      return message + ZERO_BYTES
    end

    def secure_random_key
      return SecureRandom.random_bytes(KEY_BYTES)
    end

    private def validate_key(key : Bytes)
      raise ArgumentError.new("Key must be KEY_BYTES(#{KEY_BYTES}) long") unless key.size == KEY_BYTES
    end

    private def validate_nonce(nonce : Bytes)
      raise ArgumentError.new("Nonce must be NONCE_BYTES(#{NONCE_BYTES}) long") unless nonce.size == NONCE_BYTES
    end
  end
end
