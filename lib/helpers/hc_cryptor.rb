class HcCryptor
  def self.aes128(input)
    return false if input.blank?

    cipher_text = input.gsub('-', '+').gsub('_', '/')
    cipher_text = Base64.decode64(cipher_text)
    cipher = OpenSSL::Cipher::AES128.new(:CBC)
    cipher.decrypt
    cipher.key = ENV['ECWID_CLIENT_SECRET'][0..15]
    cipher.iv = cipher_text[0..15]
    decrypted_payload = cipher.update(cipher_text[16..-1]) + cipher.final
    JSON.parse(decrypted_payload).with_indifferent_access
  end
end
