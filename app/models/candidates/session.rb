class Candidates::Session
  include ActiveModel::Model
  include ActiveModelAttributes
  include ActiveRecord::AttributeAssignment

  attr_reader :contact, :candidate, :token

  attribute :email, :string
  attribute :firstname, :string
  attribute :lastname, :string
  attribute :date_of_birth, :date

  validates :email, presence: true
  validates :email, format: /\A[^@]+@[^@]+\.[^@]+\z/, allow_blank: true
  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :date_of_birth, presence: true

  def initialize(gitis, attrs = {})
    @gitis = gitis
    assign_attributes attrs
  end

  def create_signin_token
    return false unless lookup_contact_in_gitis

    find_or_create_candidate
    generate_session_token
  end

private

  def lookup_contact_in_gitis
    contact = @gitis.find_contact_for_signin(
      email: email,
      firstname: firstname,
      lastname: lastname,
      date_of_birth: date_of_birth
    )

    if contact
      @contact = contact
    else
      false
    end
  end

  def find_or_create_candidate
    @candidate = Bookings::Candidate.find_or_create_by(gitis_uuid: contact.id)
  end

  def generate_session_token
    @token = @candidate.session_tokens.create!.token
  end
end
