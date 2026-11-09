import { Header } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { Stats } from "@/components/Stats";
import { SubjectExplorer } from "@/components/SubjectExplorer";
import { Method } from "@/components/Method";
import { Blocker } from "@/components/Blocker";
import { QuizDemo } from "@/components/QuizDemo";
import { Collections } from "@/components/Collections";
import { Profs } from "@/components/Profs";
import { Testimonials } from "@/components/Testimonials";
import { Faq } from "@/components/Faq";
import { FinalCta, Footer } from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <Stats />
        <SubjectExplorer />
        <Method />
        <Blocker />
        <QuizDemo />
        <Collections />
        <Profs />
        <Testimonials />
        <Faq />
        <FinalCta />
      </main>
      <Footer />
    </>
  );
}
