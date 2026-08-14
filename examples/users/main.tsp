import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";

using TypeSpec.Http;

@doc("User information")
model User {
  firstName: string;
  lastName: string;
  email: string;
  address: Address;
}

@doc("Address of the user")
model Address {
  street: string;
  city: string;
  country: string;
  postalCode: string;
}

@tag("User")
@route("/users")
interface Users {
  list(@query filter: string): User[];
  read(@path id: User): User;
}