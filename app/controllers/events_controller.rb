class EventsController < ApplicationController
   before_action :set_event, only: [:show, :update]

  def index
    @total_events = Event.all.to_a.delete_if {|event| !event.to_do }
    @urgent_events = Event.where("emergency_level = ?", "urgent").to_a.delete_if {|event| !event.to_do }
    @late_rent = Event.where("description = ?", "retard loyer").to_a.delete_if {|event| !event.to_do }
    @end_of_lease = Event.where("description = ?", "fin de bail").to_a.delete_if {|event| !event.to_do }
    @rent_revision = Event.where("description = ?", "révision de loyer").to_a.delete_if {|event| !event.to_do }
    @events=[]
    landing = true
    # Add a condition if you come from searchbar
    unless params[:search].blank?
      @total_events.each do |event|
        @events << event if event.lease.owner_name.downcase.include?(params[:search].downcase)
      end
    else
      # Create a hash with the params and the human redable corresponding value
      new_hash = {"late_rent" => "retard loyer", "end_of_lease" => "fin de bail", "rent_revision" => "révision de loyer"}
      # Iterate on hash to add the events ot the @events array if they are selected
      new_hash.each do |key, value|
        if params[key.to_sym] == "on"
          # Add a condition to check if the emergency level is urgent
          @events << Event.where("description = ?", value).to_a.delete_if {|event| !event.to_do }
          @events = @events.flatten
          landing = false
        end
      end
        # Return all events if nothin is selected and check if emergency level is urgent
      if @events == [] && !params.values.include?("on")
        @events = @total_events
      end
    end

    # adding some code to have checkbox's checked = true directly and adapt afterwards
    if landing && !params.values.include?("on")
      @late_rent_checked = true
      @end_of_lease_checked = true
      @rent_revision_checked = true
    else
      params[:late_rent] == "on" ? @late_rent_checked = true : @late_rent_checked = false
      params[:end_of_lease] == "on" ? @end_of_lease_checked = true : @end_of_lease_checked = false
      params[:rent_revision] == "on" ? @rent_revision_checked = true : @rent_revision_checked = false
    end

    # sorting the events array
    pivot = @events
    @events = pivot.sort_by {|event| [event.end_date, event.lease.rent_balance]}

    respond_to do |format|
      format.html
      format.js
    end
  end

  def index_urgent
    @total_events = Event.all.to_a.delete_if {|event| !event.to_do }
    @urgent_events = Event.where("emergency_level = ?", "urgent").to_a.delete_if {|event| !event.to_do }
    @late_rent = Event.where("description = ? AND emergency_level = ?", "retard loyer", "urgent").to_a.delete_if {|event| !event.to_do }
    @end_of_lease = Event.where("description = ? AND emergency_level = ?", "fin de bail", "urgent").to_a.delete_if {|event| !event.to_do }
    @rent_revision = Event.where("description = ? AND emergency_level = ?", "révision de loyer", "urgent").to_a.delete_if {|event| !event.to_do }
    # Create a hash with the params and the human redable corresponding value
    new_hash = {"late_rent" => "retard loyer", "end_of_lease" => "fin de bail", "rent_revision" => "révision de loyer"}
    @events=[]
    landing = true

    # Iterate on hash to add the events ot the @events array if they are selected
    new_hash.each do |key, value|
      if params[key.to_sym] == "on"
        # Add a condition to check if the emergency level is urgent
        @events << Event.where("description = ? AND emergency_level = ?", value, "urgent").to_a.delete_if {|event| !event.to_do }
        @events = @events.flatten
        landing = false
      end
    end
      # Return all events if nothin is selected and check if emergency level is urgent
    if @events == [] && !params.values.include?("on")
      @events = @urgent_events
    end

    # adding some code to have checkbox's checked = true directly and adapt afterwards
    if landing && !params.values.include?("on")
      @late_rent_checked = true
      @end_of_lease_checked = true
      @rent_revision_checked = true
    else
      params[:late_rent] == "on" ? @late_rent_checked = true : @late_rent_checked = false
      params[:end_of_lease] == "on" ? @end_of_lease_checked = true : @end_of_lease_checked = false
      params[:rent_revision] == "on" ? @rent_revision_checked = true : @rent_revision_checked = false
    end

    # sorting the events array
    pivot = @events
    @events = pivot.sort_by {|event| [event.end_date, event.lease.rent_balance]}

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @event.update(new_rent: params[:event][:new_rent].to_i)
    respond_to do |format|
      format.html do
        render :show
      end
      format.js
    end
  end



  def show
    @comment = Comment.new
  end

  def letter
    @event = Event.find(params[:event_id])
    respond_to do |format|
      format.pdf do
        render pdf: "letter", disposition: "attachment"
      end
    end
    if @event.status == 'owner_to_contact'
      @event.update(status: 'tenant_to_notify', com_owner: "lettre")
    else
      @event.update(status: 'tenant_notified', to_do: false, com_tenant: "lettre")
    end
  end

  def mail
    @event = Event.find(params[:event_id])
    # Instruction to get params and fill it in a new mail instance and send it
    if @event.status == 'owner_to_contact'
      EventMailer.notify_owner(@event, params[:response]).deliver_now
      @event.update(status: 'owner_contacted', com_owner: "mail")
    else
      EventMailer.notify_tenant(@event, params[:response]).deliver_now
      @event.update(status: 'tenant_notified', to_do: false, com_tenant: "mail")
    end
  end

  def home
  end

  private
  def set_event
     @event = Event.find(params[:id])
  end
end
