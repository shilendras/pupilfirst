require 'rails_helper'

describe ConnectRequests::ConfirmationService do
  subject { described_class.new(connect_request) }

  let!(:connect_request) { create :connect_request, status: ConnectRequest::STATUS_REQUESTED }

  describe '#execute' do
    let(:faculty_mailer) { double FacultyMailer }
    let(:startup_mailer) { double StartupMailer }
    let(:mock_calendar_service) { instance_double ConnectRequests::CreateCalendarEventService, execute: nil }

    it 'sends mail for confirmed, saves confirmation time, sets up google calendar event and creates rating/reminder jobs' do
      expect(FacultyMailer).to receive(:connect_request_confirmed).with(connect_request).and_return(faculty_mailer)
      expect(StartupMailer).to receive(:connect_request_confirmed).with(connect_request).and_return(startup_mailer)
      expect(faculty_mailer).to receive(:deliver_later)
      expect(startup_mailer).to receive(:deliver_later)

      expect(ConnectRequests::CreateCalendarEventService).to receive(:new).with(connect_request).and_return(mock_calendar_service)

      subject.execute

      expect(FacultyConnectSessionRatingJob).to have_been_enqueued.with(connect_request.id).at(connect_request.connect_slot.slot_at + 45.minutes)
      expect(FacultyConnectSessionReminderJob).to have_been_enqueued.with(connect_request.id).at(connect_request.connect_slot.slot_at - 30.minutes)
    end
  end
end
