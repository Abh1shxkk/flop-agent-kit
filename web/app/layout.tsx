import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Hydra Console | Technocore Agent Kit",
  description: "A browser-first console for creating and using a Technocore DID.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
