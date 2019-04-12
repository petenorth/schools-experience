require 'rails_helper'

describe Schools::OnBoarding::CurrentStep do
  context '.for' do
    let :returned_step do
      described_class.for school_profile
    end

    context 'candidate_requirement required' do
      let :school_profile do
        FactoryBot.build_stubbed :school_profile
      end

      it 'returns :candidate_requirement' do
        expect(returned_step).to eq :candidate_requirement
      end
    end

    context 'candidate_requirement not required' do
      context 'fees required' do
        let :school_profile do
          FactoryBot.build_stubbed :school_profile, :with_candidate_requirement
        end

        it 'returns :fees' do
          expect(returned_step).to eq :fees
        end
      end

      context 'fees not required' do
        context 'administration_fee required' do
          let :school_profile do
            FactoryBot.build_stubbed :school_profile,
              :with_candidate_requirement,
              fees_administration_fees: true,
              fees_dbs_fees: false,
              fees_other_fees: false
          end

          it 'returns :administration_fee' do
            expect(returned_step).to eq :administration_fee
          end
        end

        context 'administration_fee not required' do
          context 'dbs_fee required' do
            let :school_profile do
              FactoryBot.build_stubbed :school_profile,
                :with_candidate_requirement,
                fees_administration_fees: false,
                fees_dbs_fees: true,
                fees_other_fees: false
            end

            it 'returns :dbs_fee' do
              expect(returned_step).to eq :dbs_fee
            end
          end

          context 'dbs_fee not required' do
            context 'other_fees required' do
              let :school_profile do
                FactoryBot.build_stubbed :school_profile,
                  :with_candidate_requirement,
                  fees_administration_fees: false,
                  fees_dbs_fees: false,
                  fees_other_fees: true
              end

              it 'returns :other_fees' do
                expect(returned_step).to eq :other_fee
              end
            end

            context 'other_fees not required' do
              context 'phases_list required' do
                let :school_profile do
                  FactoryBot.build_stubbed :school_profile,
                    :with_candidate_requirement,
                    fees_administration_fees: false,
                    fees_dbs_fees: false,
                    fees_other_fees: false
                end

                it 'returns :phases_list' do
                  expect(returned_step).to eq :phases_list
                end
              end
            end
          end
        end
      end
    end
  end
end