require 'spec_helper'

class Item < Sequel::Model
  plugin :enum
  enum :condition, [:mint, :very_good, :good, :poor]
  enum :edition, { first: 0, second: 1, rare: 2, other: 3 }
end

AbstractModel = Class.new(Sequel::Model)
AbstractModel.require_valid_table = false
AbstractModel.plugin :enum

class RealModel < AbstractModel
  enum :condition, [:mint, :very_good, :fair]
end

class Conflict < Sequel::Model
  plugin :enum
  enum :status, [:open, :waiting, :finished]
end

describe "sequel_enum" do
  let(:item) { Item.new }

  specify "class should provide reflection" do
    expect(Item.enums[:condition]).to eq({ mint: 0, very_good: 1, good: 2, poor: 3 })
    expect(Item.enums[:edition]).to eq({ first: 0, other: 3, rare: 2, second: 1 })
  end

  specify "inheriting from abstract model should provide reflection" do
    expect(RealModel.enums).to eq({ condition: { :mint => 0, :very_good => 1, :fair => 2}})
  end

  specify "it raises ArgumentError when enum conflict definition" do
    expect do
      Conflict.enum :status, [:new, :pending, :closed]
    end.to raise_error(ArgumentError, /You tried to define an enum named "status" on the model "Conflict"/)
  end

  specify "it rejects when it's not an array or hash" do
    expect{
      Item.enum :state, 'whatever'
    }.to raise_error(ArgumentError)
  end

  specify "generate a class method to access the enum mapping" do
    expect(Item.conditions).to eq({mint: 0, very_good: 1, good: 2, poor: 3})
    expect(Item.editions).to eq({first: 0, second: 1, rare: 2, other: 3})
  end

  describe "methods" do

    describe "#initialize_set" do
      it "handles multiple enums" do
        i = Item.create(:condition => :mint, :edition => :first)

        expect(i[:condition]).to eq 0
        expect(i[:edition]).to eq 0
      end
    end

    describe "#update" do
      it "accepts strings" do
        i = Item.create(:condition => "mint")
        expect(i[:condition]).to eq 0
      end

      it "handles multiple enums" do
        i = Item.create(:condition => :mint, :edition => :first)
        i.update(:edition => :second)

        expect(i[:edition]).to eq 1
      end
    end

    describe "#column=" do
      context "with a valid value" do
        it "should set column to the value index" do
          item.condition = :mint
          expect(item[:condition]).to be 0
        end
      end

      context "with an invalid value" do
        it "should set column to nil" do
          item.condition = :fair
          expect(item[:condition]).to be_nil
        end
      end
    end

    describe "#column" do
      context "with a valid index stored on the column" do
        it "should return its matching value" do
          item[:condition] = 1
          expect(item.condition).to be :very_good
        end
      end

      context "with an invalid index stored on the column" do
        it "should return nil" do
          item[:condition] = 10
          expect(item.condition).to be_nil
        end
      end
    end

    describe "#column?" do
      context "when the actual value match" do
        it "should return true" do
          item.condition = :good
          expect(item.good?).to be true
        end
      end

      context "when the actual value doesn't match" do
        it "should return false" do
          item.condition = :mint
          expect(item.poor?).to be false
        end
      end
    end
  end
end
