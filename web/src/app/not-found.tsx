import Link from "next/link";
import { SiteHeader } from "@/components/SiteChrome";
import { ButtonLink, container } from "@/components/ui";

export default function NotFound() {
  return (
    <>
      <SiteHeader />
      <main className={`${container} flex flex-col items-start gap-5 py-24`}>
        <span className="text-[13px] font-bold uppercase tracking-[1.2px] text-blue">404</span>
        <h1 className="text-[40px] font-extrabold tracking-[-1px]">This page does not exist.</h1>
        <p className="max-w-[560px] text-[17px] text-ink-3">The course or author you are looking for may have moved. The catalogue is one click away.</p>
        <div className="flex gap-3">
          <ButtonLink href="/courses">Explore the courses</ButtonLink>
          <Link href="/" className="inline-flex h-11 items-center px-4 text-[15px] font-bold text-navy">Back home</Link>
        </div>
      </main>
    </>
  );
}
