pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address public owner;
    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
      string description;
      string URL;
      uint totalTickets;
      uint sales;
      mapping (address => uint) buyers;
      bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier isOwner() {
      require(
        msg.sender == owner,
        "Only owner can call this function."
        );
        _;
    }
    constructor()
    public
    {
      owner = msg.sender;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _URL, uint _tickets)
      public
      isOwner()
      returns (uint)
    {
      uint eventID = idGenerator;
      events[eventID] = Event({description: _description, URL: _URL, totalTickets: _tickets, isOpen: true}
        );
      idGenerator += 1;
      emit LogEventAdded(_description, _URL, _tickets, eventID);
      return eventID;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _eventID)
      public
      returns (string memory _description, string memory _URL, uint _tickets, uint _sales, bool _isOpen)
    {
      Event memory myEvent = events[_eventID];
      return (myEvent.description, myEvent.URL, myEvent.tikets, myEvent.sales, myEvent.isOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _eventID, uint _buyTickets)
      public
    {
      require(
        events[_eventID].isOpen == true,
        "Verify the event isOpen"
      );
      require(
        msg.value > (_buyTickets * PRICE_TICKET),
        "Verify enough funds to buy tickets"
      );
      require(
        events[_eventID].totalTickets > _buyTickets,
        "Verify there are enough tickets to purchase"
      );
      events[_eventID].buyers[msg.sender] += _buyTickets;
      events[_eventID].sales += _buyTickets;
      msg.sender.transfer(msg.value - _buyTickets * PRICE_TICKET);
      emit LogBuyTickets(msg.sender, _eventID, _buyTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventID)
      public
      payable
    {
      require(
        events[_eventID].buyers[msg.senders] > 0,
        "Verify users has purchased tickets"
      );
      events[_eventID].sales -= events[_eventID].buyers[msg.sender];
      msg.sender.transfer(events[_eventID].buyers[msg.sender] * PRICE_TICKET);
      emit LogGetRefund(msg.sender, _eventID, events[_eventID].buyers[msg.sender]);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventID)
      public
      view
      returns(uint)
    {
      return events[_eventID].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventID)
      public
      payable
      isOwner()
    {
      events[_eventID].isOpen = false;
      owner.transfer(events[_eventID].sales * PRICE_TICKET);
      emit LogEndSale(owner, address(this).balance, _eventID);
    }
}
