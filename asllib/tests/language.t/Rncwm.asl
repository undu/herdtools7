// RUN: interp %s | FileCheck %s
// CHECK: 1000
// CHECK-NEXT: 32

func main() => integer
begin
    print(exp_int(10, 3));
    print(exp_int(2, 5));
    return 0;
end
