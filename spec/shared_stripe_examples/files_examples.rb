require 'spec_helper'
shared_examples 'Files API' do
  describe 'Create a new File' do
    it 'creates a new file' do
      file = Stripe::File.create(purpose: 'dispute_evidence', file: '')
      expect(file.object).to eq('file')
      expect(file.purpose).to eq('dispute_evidence')
    end
  end

  describe 'Retrieves a File' do
    it 'retrieves a specific file' do
      original = Stripe::File.create(purpose: 'dispute_evidence', file: '')
      file = Stripe::File.retrieve(original.id)

      expect(file).to be_a Stripe::File
      expect(file.id).to match /file\_/
    end
  end

  describe "listing payouts" do
    before do
      3.times do
        Stripe::File.create(purpose: 'dispute_evidence', file: '')
      end
    end

    it "without params retrieves all files" do
      expect(Stripe::File.all.count).to eq(3)
    end

    it "accepts a limit param" do
      expect(Stripe::File.all(limit: 2).count).to eq(2)
    end
  end
end
