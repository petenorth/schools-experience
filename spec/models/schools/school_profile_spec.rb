require 'rails_helper'

describe Schools::SchoolProfile, type: :model do
  context 'candidate_requirement' do
    context 'attributes' do
      it do
        is_expected.to have_db_column(:urn).of_type :integer
      end

      it do
        is_expected.to \
          have_db_column(:candidate_requirement_dbs_requirement).of_type :string
      end

      it do
        is_expected.to \
          have_db_column(:candidate_requirement_dbs_policy).of_type :text
      end

      it do
        is_expected.to \
          have_db_column(:candidate_requirement_requirements).of_type :boolean
      end

      it do
        is_expected.to \
          have_db_column(:candidate_requirement_requirements_details).of_type :text
      end

      it do
        is_expected.to \
          have_db_column(:fees_administration_fees).of_type :boolean
      end

      it do
        is_expected.to have_db_column(:fees_dbs_fees).of_type :boolean
      end

      it do
        is_expected.to have_db_column(:fees_other_fees).of_type :boolean
      end

      it do
        is_expected.to \
          have_db_column(:administration_fee_amount_pounds)
            .of_type(:decimal).with_options(precision: 6, scale: 2)
      end

      it do
        is_expected.to \
          have_db_column(:administration_fee_description).of_type :text
      end

      it do
        is_expected.to \
          have_db_column(:administration_fee_interval).of_type :string
      end

      it do
        is_expected.to \
          have_db_column(:administration_fee_payment_method).of_type :text
      end
    end

    context 'validations' do
      it do
        is_expected.to validate_presence_of :urn
      end
    end

    context 'values from form models' do
      let :model do
        described_class.new urn: 1234567890
      end

      context '#candidate_requirement' do
        let :form_model do
          FactoryBot.build :candidate_requirement
        end

        before do
          model.candidate_requirement = form_model
        end

        it 'sets candidate_requirement_dbs_requirement' do
          expect(model.candidate_requirement_dbs_requirement).to eq \
            form_model.dbs_requirement
        end

        it 'sets candidate_requirement_dbs_policy' do
          expect(model.candidate_requirement_dbs_policy).to eq \
            form_model.dbs_policy
        end

        it 'sets candidate_requirement_requirements' do
          expect(model.candidate_requirement_requirements).to eq \
            form_model.requirements
        end

        it 'sets candidate_requirement_requirements_details' do
          expect(model.candidate_requirement_requirements_details).to eq \
            form_model.requirements_details
        end

        it 'returns the form model' do
          expect(model.candidate_requirement).to eq form_model
        end
      end

      context '#fees' do
        let :form_model do
          FactoryBot.build :fees
        end

        before do
          model.fees = form_model
        end

        it 'sets fees_administration_fees' do
          expect(model.fees_administration_fees).to eq \
            form_model.administration_fees
        end

        it 'sets fees_dbs_fees' do
          expect(model.fees_dbs_fees).to eq form_model.dbs_fees
        end

        it 'sets fees_other_fees' do
          expect(model.fees_other_fees).to eq form_model.other_fees
        end

        it 'returns the form model' do
          expect(model.fees).to eq form_model
        end
      end

      context '#administration_fee' do
        let :form_model do
          FactoryBot.build :administration_fee
        end

        before do
          model.administration_fee = form_model
        end

        it 'sets administration_fee_amount_pounds' do
          expect(model.administration_fee_amount_pounds).to \
            eq form_model.amount_pounds
        end

        it 'sets administration_fee_description' do
          expect(model.administration_fee_description).to \
            eq form_model.description
        end

        it 'sets administration_fee_interval' do
          expect(model.administration_fee_interval).to eq form_model.interval
        end

        it 'sets administration_fee_payment_method' do
          expect(model.administration_fee_payment_method).to \
            eq form_model.payment_method
        end

        it 'returns the form model' do
          expect(model.administration_fee).to eq form_model
        end
      end
    end
  end
end
