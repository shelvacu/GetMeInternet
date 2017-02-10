describe Sodium::SecretBox do
  it "is sane" do
    Sodium::SecretBox.sanity_check.should be_true
  end

  it "encrypts and decrypts" do
    test = "Hi, my name is bob. 1234567890!@#$%^&*()".to_slice
    key = Sodium::SecretBox.secure_random_key
    Sodium::SecretBox.decrypt(
      Sodium::SecretBox.encrypt(test, key),
      key
    ).should eq test
  end
end
