//
//  Created by Colin Fallon on 18/09/2025.
//

import Foundation


struct PlanyoResponse<T: Decodable>: Decodable {
  
  var data: T
  let responseCode: Int
  let responseMessage: String
}

public struct Reservation: Decodable {
  enum CodingKeys: String, CodingKey {
    case reservationId, firstName, lastName, creationTime, startTime, endTime, email, status, phoneNumber, totalPrice, amountPaid, properties, adminNotes, userNotes, regularProducts
    case room = "name"
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    reservationId = try container.decodeIfPresent(Int.self, forKey: .reservationId)
    firstName = try container.decode(String.self, forKey: .firstName)
    lastName = try container.decode(String.self, forKey: .lastName)
    creationTime = try container.decode(Date.self, forKey: .creationTime)
    startTime = try container.decode(Date.self, forKey: .startTime)
    endTime = try container.decode(Date.self, forKey: .endTime)
    email = try container.decode(String.self, forKey: .email)
    phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
    room = try container.decode(String.self, forKey: .room)
    properties = try container.decode(ReservationProperties.self, forKey: .properties)
    let statusString = try container.decode(String.self, forKey: .status)
    status = Int(statusString) ?? 0
    let totalPriceString = try container.decode(String.self, forKey: .totalPrice)
    totalPrice = Decimal(string: totalPriceString) ?? 0
    let amountPaidString = try container.decode(String.self, forKey: .amountPaid)
    amountPaid = Decimal(string: amountPaidString) ?? 0
    adminNotes = try container.decode(String.self, forKey: .adminNotes)
    userNotes = try container.decode(String.self, forKey: .userNotes)
    regularProducts = try container.decode([RegularProduct].self, forKey: .regularProducts)
  }
  
  public var reservationId: Int?
  public let firstName: String
  public let lastName: String
  public let room: String
  public let creationTime: Date
  public let startTime: Date
  public let endTime: Date
  public let email: String
  public let phoneNumber: String
  public let status: Int
  public let totalPrice: Decimal
  public let amountPaid: Decimal
  public let properties: ReservationProperties
  public let adminNotes: String?
  public let userNotes: String?
  public let regularProducts: [RegularProduct]?
}

public struct ReservationProperties: Decodable {
  enum CodingKeys: String, CodingKey {
    case agency, persons, bedFormatRequired, allergies, walkingRoute
    case guest1FirstName = "First_Name_1"
    case guest1LastName = "Last_name_1"
    case guest2FirstName = "First_Name_2"
    case guest2LastName = "Last_name_2"
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.agency) {
      agency = try container.decode(String.self, forKey: .agency)
    } else {
      agency = "Direct"
    }
    if container.contains(.bedFormatRequired) {
      bedFormatRequired = try container.decode(String.self, forKey: .bedFormatRequired)
    } else {
      bedFormatRequired = "Double"
    }
    allergies = try container.decodeIfPresent(String.self, forKey: .allergies)
    walkingRoute = try container.decodeIfPresent(String.self, forKey: .walkingRoute)
    guest1FirstName = try container.decodeIfPresent(String.self, forKey: .guest1FirstName)
    guest1LastName = try container.decodeIfPresent(String.self, forKey: .guest1LastName)
    guest2FirstName = try container.decodeIfPresent(String.self, forKey: .guest2FirstName)
    guest2LastName = try container.decodeIfPresent(String.self, forKey: .guest2LastName)
    let personsString = try container.decode(String.self, forKey: .persons)
    persons = Int(personsString) ?? 0
  }
    
  public let agency: String
  public let persons: Int
  public let bedFormatRequired: String
  public let allergies: String?
  public let walkingRoute: String?
  public let guest1FirstName: String?
  public let guest1LastName: String?
  public let guest2FirstName: String?
  public let guest2LastName: String?
}

public struct RegularProduct: Decodable {
  enum CodingKeys: String, CodingKey {
    case id, name, unitPrice, quantity
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    let unitPriceString = try container.decode(String.self, forKey: .unitPrice)
    unitPrice = Decimal(string: unitPriceString) ?? 0
    let quantityString = try container.decode(String.self, forKey: .quantity)
    quantity = Int(quantityString) ?? 0
  }
  
  public let id: String
  public let name: String
  public let unitPrice: Decimal
  public let quantity: Int
  
}
