import { redirect } from "next/navigation";

export default function DemoLoginPage(): never {
  redirect("/api/admin/demo-login");
}
