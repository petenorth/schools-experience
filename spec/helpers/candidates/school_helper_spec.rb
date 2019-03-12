require 'rails_helper'

RSpec.describe Candidates::SchoolHelper, type: :helper do
  context '.format_school_address' do
    before do
      @school = OpenStruct.new(
        address_1: nil,
        address_2: 'Picadilly Gate',
        address_3: '',
        town: 'Manchester',
        county: 'Manchester',
        postcode: 'MA1 1AM'
      )

      @formatted = format_school_address(@school)
    end

    it 'should be html_safe' do
      expect(@formatted.html_safe?).to be true
    end

    it 'should concatenate non blank fields' do
      expect(@formatted).to eq "Picadilly Gate, Manchester, Manchester, MA1 1AM"
    end
  end

  context '.format_school_subjects' do
    before do
      @school = OpenStruct.new(
        subjects: [
          OpenStruct.new(id: 1, name: 'First'),
          OpenStruct.new(id: 2, name: 'Second'),
          OpenStruct.new(id: 3, name: 'Third')
        ]
      )

      @formatted = format_school_subjects(@school)
    end

    it 'should be html_safe' do
      expect(@formatted.html_safe?).to be true
    end

    it 'should turn them into a sentence' do
      expect(@formatted).to eq "First, Second, and Third"
    end
  end

  context '.format_school_phases' do
    before do
      @school = OpenStruct.new(
        phases: [
          OpenStruct.new(id: 1, name: 'First'),
          OpenStruct.new(id: 2, name: 'Second'),
          OpenStruct.new(id: 3, name: 'Third')
        ]
      )

      @formatted = format_school_phases(@school)
    end

    it 'should be html_safe' do
      expect(@formatted.html_safe?).to be true
    end

    it 'should turn them into a sentence' do
      expect(@formatted).to eq "First, Second, Third"
    end
  end

  context '.current_search' do
    context 'with coordinates search' do
      subject do
        double('Coords search',
          latitude: '1',
          longitude: '2',
          location: '',
          query: '')
      end

      it('should say near me') do
        expect(describe_current_search(subject)).to match(/near me/)
      end
    end

    context 'with location search' do
      subject do
        double('Location search',
          latitude: '',
          longitude: '',
          location: 'Manchester',
          query: '')
      end

      it('should say near Manchester') do
        expect(describe_current_search(subject)).to match(/near Manchester/i)
      end
    end

    context 'with query search' do
      subject do
        double('Text search',
          latitude: '',
          longitude: '',
          location: '',
          query: 'special school')
      end

      it('should say matching special school') do
        expect(describe_current_search(subject)).to \
          match(/matching special school/i)
      end
    end
  end

  context '.school_location_map' do
    include Candidates::MapsHelper

    before do
      @orig_api_key = ENV['BING_MAPS_KEY']
      ENV['BING_MAPS_KEY'] = '12345'
      @latitude = "53.4782"
      @longitude = "-2.2299"
      @school = OpenStruct.new(
        name: 'Stub School',
        coordinates: OpenStruct.new(latitude: @latitude, longitude: @longitude)
        )
    end

    after { ENV['BING_MAPS_KEY'] = @orig_api_key }

    subject { school_location_map @school }

    it('should return a correct Bing Maps for schools location') do
      expect(subject).to match(/<img /)
      expect(subject).to match("#{@latitude}%2C#{@longitude}")
    end
  end

  context '.filter_description' do
    context 'with no filters' do
      subject do
        double('Bookings::SchoolSeach',
          subjects: [], subject_names: [],
          phases: [], phase_names: [])
      end

      it("should return a nil") do
        expect(school_search_filter_description(subject)).to be_nil
      end
    end

    context 'with subject filters' do
      subject do
        double('Bookings::SchoolSeach',
          subjects: [1, 3], subject_names: %w{first third},
          phases: [], phase_names: [])
      end

      it("should return a nil") do
        expect(school_search_filter_description(subject)).to \
          eq("Filtering by Placement subject: first and third")
      end
    end

    context 'with phase filters' do
      subject do
        double('Bookings::SchoolSeach',
          subjects: [], subject_names: [],
          phases: [1, 3], phase_names: %w{first third})
      end

      it("should return a nil") do
        expect(school_search_filter_description(subject)).to \
          eq("Filtering by Education phase: first and third")
      end
    end

    context 'with subject and phase filters' do
      subject do
        double('Bookings::SchoolSeach',
          subjects: [1, 3], subject_names: %w{first third},
          phases: [1, 3], phase_names: %w{first third})
      end

      it("should return a nil") do
        expect(school_search_filter_description(subject)).to \
          eq("Filtering by Education phase and Placement subject: first, third and first, third")
      end
    end
  end
end
