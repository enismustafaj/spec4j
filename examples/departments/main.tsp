import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";


using TypeSpec.Http;

@doc("Department Information")
model Department {
    id: string;
    dep_name: string;
    dep_location: string;
    num_employeers: string;
}

@route("/departments")
interface Users {
    list(@query filter: string): Department[];
    read(@path id: string): Department;
}