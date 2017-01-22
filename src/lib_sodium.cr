@[Link("sodium")]
lib LibSodium
  fun sodium_version_string : UInt8*
  fun crypto_generichash_primitive : UInt8*
  fun crypto_generichash_blake2b_bytes_min : UInt8
  fun crypto_generichash_blake2b_bytes_max : UInt8
  fun crypto_sign_ed25519_seedbytes : UInt16
  fun crypto_sign_ed25519_publickeybytes : UInt16
  fun crypto_sign_ed25519_secretkeybytes : UInt16
  fun crypto_sign_ed25519_bytes : UInt16
  fun crypto_sign_ed25519_seed_keypair(UInt8*, UInt8*, UInt8*) : LibC::Int
  fun randombytes_buf(UInt8*, UInt16)
  fun crypto_sign_ed25519(UInt8*, UInt64*, UInt8*, UInt64, UInt8*) : LibC::Int
  fun crypto_sign_ed25519_open(UInt8*, UInt64*, UInt8*, UInt64, UInt8*) : LibC::Int
  fun crypto_sign_ed25519_verify_detached(UInt8*, UInt8*, UInt64, UInt8*) : LibC::Int
  fun crypto_secretbox(
    ciphertext : UInt8*, #out 
    message : UInt8*, 
    message_len : UInt64,
    nonce : UInt8*,
    key : UInt8*
  ) : LibC::Int
  fun crypto_secretbox_open(
    message : UInt8*, #out
    ciphertext : UInt8*,
    ciphertext_len : UInt64,
    nonce : UInt8*,
    key : UInt8*
  ) : LibC::Int
  fun crypto_secretbox_keybytes : LibC::SizeT
  fun crypto_secretbox_noncebytes : LibC::SizeT
  fun crypto_secretbox_zerobytes : LibC::SizeT
  fun crypto_secretbox_boxzerobytes : LibC::SizeT
end
