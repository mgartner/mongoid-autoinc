require "spec_helper"

describe "Mongoid::Autoinc" do

  after do
    User.delete_all
  end

  context "class methods" do

    subject { User }

    it { should respond_to(:increments) }

    it { should respond_to :incrementing_fields }

    describe "incrementing_fields" do

      subject { User.incrementing_fields }

      it { should == {:number => {:auto => true}} }

      it "should protect number" do
        User.protected_attributes.include? :number
      end

      context "for SpecialUser" do

        subject { SpecialUser.incrementing_fields }

        it { should == {:number => {:auto => true}} }

        it "should protect number" do
          User.protected_attributes.include? :number
        end

      end

      context "for PatientFile" do

        subject { PatientFile.incrementing_fields }

        it { should == {:file_number => {:scope => :name, :auto => true}} }

      end

      context "for Operation" do

        subject { Operation.incrementing_fields }

        it { should == {:op_number => {:scope => subject[:op_number][:scope], :auto => true}} }
        it { subject[:op_number][:scope].should be_a Proc }

      end

      context "for Vehicle" do

        subject { Vehicle.incrementing_fields }

        it { should == {:vin => {:seed => 1000, :auto => true}} }
        
      end

      context "for Ticket" do

        subject { Ticket.incrementing_fields }

        it { should == {:number => {:step => 2, :auto => true}} }

      end

      context "for LotteryTicket" do

        subject { LotteryTicket.incrementing_fields }

        it { should == {:number => {:step => subject[:number][:step], :auto => true}} }
        it { subject[:number][:step].should be_a Proc }

      end

    end

  end

  context "instance methods" do

    let(:incrementor) { Object.new }

    before { incrementor.stub!(:inc).and_return(1) }

    context "without scope" do

      subject { User.new }

      it { should respond_to(:update_auto_increments) }

      describe "before create" do

        let(:user) { User.new(:name => 'Dr. Cox') }

        it "should call the autoincrementor" do
          Mongoid::Autoinc::Incrementor.should_receive(:new).
            with('User', :number, {auto: true}).
            and_return(incrementor)

          user.save!
        end

        describe "writing the attribute" do

          before { Mongoid::Autoinc::Incrementor.stub!(:new).and_return(incrementor) }

          it "should write the returned incrementor attribute" do
            expect{
              user.save!
            }.to change(user, :number).from(nil).to(1)
          end

        end

        describe "#assign!" do

          it "should raise AutoIncrementsError" do
            expect { subject.assign!(:number) }.
              to raise_error(Mongoid::Autoinc::AutoIncrementsError)
          end

        end

      end

    end

    context "with scope as symbol" do

      describe "before create" do

        let(:patient_file) { PatientFile.new(:name => 'Dr. Cox') }

        it "should call the autoincrementor" do
          Mongoid::Autoinc::Incrementor.should_receive(:new).
            with('PatientFile', :file_number, {scope: 'Dr. Cox', auto: true}).
            and_return(incrementor)

          patient_file.save!
        end

      end

    end

    context "with scope as proc" do

      describe "before create" do

        let(:user) { User.new(:name => 'Dr. Cox') }
        let(:operation) { Operation.new(:name => 'Heart Transplant', :user => user) }

        it "should call the autoincrementor" do
          Mongoid::Autoinc::Incrementor.should_receive(:new).
              with('Operation', :op_number, {scope: 'Dr. Cox', auto: true}).
              and_return(incrementor)

          operation.save!
        end

      end

    end

    context "without auto" do

      subject { Intern.new }

      describe "before create" do

        it "should not call the autoincrementor" do
          Mongoid::Autoinc::Incrementor.should_not_receive(:new)

          subject.save!
        end

      end

      describe "#assign!" do

        it "should call the autoincrementor" do
          Mongoid::Autoinc::Incrementor.should_receive(:new).
            with('Intern', :number, {auto: false}).and_return(incrementor)

          subject.assign!(:number)
        end

        it "should raise when called more than once per document" do
          subject.assign!(:number)
          expect { subject.assign!(:number) }.
            to raise_error(Mongoid::Autoinc::AlreadyAssignedError)
        end

      end

      context "class with overwritten model name" do

        subject { Intern.new }

        before { Intern.stub(:model_name => 'PairOfScrubs') }

        it "should call the autoincrementor" do
          Mongoid::Autoinc::Incrementor.should_receive(:new).
            with('PairOfScrubs', :number, {auto: false}).and_return(incrementor)

          subject.assign!(:number)
        end

      end

    end

    context "with seed" do

      describe "before create" do

        let(:vehicle) { Vehicle.new(:model => 'Coupe') }

        it "should call the autoincrementor with the seed value" do
          Mongoid::Autoinc::Incrementor.should_receive(:new).
            with('Vehicle', :vin, {seed: 1000, auto: true}).
            and_return(incrementor)

          vehicle.save!
        end

      end

    end

    context "with Integer step" do

      describe "before create" do

        let(:ticket) { Ticket.new }

        it "should call the autoincrementor with the options hash" do
          Mongoid::Autoinc::Incrementor.should_receive(:new).
            with('Ticket', :number, {step: 2, auto: true}).
            and_return(incrementor)

          ticket.save!
        end

      end

    end

    context "with Proc step" do

      describe "before create" do

        let(:lottery_ticket) { LotteryTicket.new(start: 10) }

        it "should call the autoincrementor with the options hash" do
          Mongoid::Autoinc::Incrementor.should_receive(:new).
            with('LotteryTicket', :number, {step: 11, auto: true}).
            and_return(incrementor)

          lottery_ticket.save!
        end

      end

    end

  end

end
