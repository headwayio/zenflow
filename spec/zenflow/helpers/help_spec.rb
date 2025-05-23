require 'spec_helper'

describe Zenflow::Help do
  describe "Zenflow.Help" do
    it "initializes and returns a new Zenflow::Help object" do
      expect(Zenflow.Help.class).to eq(Zenflow::Help.new.class)
    end
  end

  subject do
    Zenflow::Help.new(
      command: 'test-help',
      summary: "tests Zenflow::Help",
      usage: "test-help (optional please)",
      commands: ['test-help', 'spec-help']
    )
  end

  it { expect(subject.banner).to match(/Summary/) }
  it { expect(subject.banner).to match(/Usage/) }
  it { expect(subject.banner).to match(/Available Commands/) }
  it { expect(subject.banner).to match(/Options/) }

  context "#unknown_command" do
    describe "when the command is missing" do
      it "logs the error and exits" do
        expect(Zenflow).to receive(:Log).with "Missing command", color: :red
        expect { Zenflow::Help.new.unknown_command }.to raise_error(SystemExit)
      end
    end

    describe "when the command is present" do
      it "logs the error and exits" do
        expect(Zenflow).to receive(:Log).with 'Unknown command "test-unknown_command"', color: :red
        expect do
          Zenflow::Help.new(command: 'test-unknown_command').unknown_command
        end.to raise_error(SystemExit)
      end
    end
  end
end
