# frozen_string_literal: true

RSpec.describe "基本的な算術演算" do
  let!(:result) { 1 + 1 }
  describe "足し算" do
    it "1 + 1 は 2 になること" do
      expect(1 + 1).to eq(result)
    end
  end
end
