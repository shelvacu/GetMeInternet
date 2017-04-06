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
      return true
    end

    def encrypt(message : Bytes, key : Bytes)
      validate_key(key)
      padded_message_length = message.size + ZERO_BYTES
      padded_message = Bytes.new(padded_message_length)
      message.copy_to padded_message + ZERO_BYTES
      nonce = secure_random_nonce
      ciphertext = Bytes.new(padded_message.size)
      LibSodium.crypto_secretbox(ciphertext, padded_message, padded_message.size, nonce, key)
      return ciphertext, nonce
    end

    def decrypt(cipher_nonce : Tuple(Bytes, Bytes), key)
      decrypt(cipher_nonce[0], cipher_nonce[1], key)
    end
    
    def decrypt(ciphertext : Bytes, nonce : Bytes, key : Bytes)
      message = Bytes.new(ciphertext.size)
      return decrypt_into(ciphertext, nonce, key, message,
                          skip_message_validation: true)
    end

    def decrypt_into(ciphertext : Bytes, nonce : Bytes, key : Bytes, m : Bytes, skip_message_validation = false)
      raise ArgumentError.new("result Bytes must be same length as ciphertext Bytes") unless ciphertext.size == result.size
      validate_key(key)
      validate_nonce(nonce)
      validate_ciphertext(ciphertext)
      validate_messagetext(m) unless skip_message_validation
      res = LibSodium.crypto_secretbox_open(m, ciphertext, ciphertext.size, nonce, key)
      if res == 0 #succesfully decrypted and validated
        return m + ZERO_BYTES
      elsif res == -1
        #TODO: Deal with this better
        raise "Invalid cryptotext!"
      else
        raise "This should never happen"
      end
    end

    def secure_random_key
      return SecureRandom.random_bytes(KEY_BYTES)
    end

    def secure_random_nonce
      return SecureRandom.random_bytes(NONCE_BYTES)
    end

    private def validate_messagetext(m : Bytes)
      raise ArgumentError.new("Invalid messagetext") unless m[0,ZERO_BYTES].all?{|b| b == 0}
    end
    
    private def validate_ciphertext(ciphertext : Bytes)
      raise ArgumentError.new("Invalid ciphertext") unless ciphertext[0, BOX_ZERO_BYTES].all?{|b| b == 0}
    end
    
    private def validate_key(key : Bytes)
      raise ArgumentError.new("Key must be KEY_BYTES(#{KEY_BYTES}) long") unless key.size == KEY_BYTES
    end

    private def validate_nonce(nonce : Bytes)
      raise ArgumentError.new("Nonce must be NONCE_BYTES(#{NONCE_BYTES}) long") unless nonce.size == NONCE_BYTES
    end
  end
end
