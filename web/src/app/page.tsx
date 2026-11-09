import { Header } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { Proof } from "@/components/Proof";
import { Feed } from "@/components/Feed";
import { ReaderStory } from "@/components/ReaderStory";
import { Blocker } from "@/components/Blocker";
import { QuizDemo } from "@/components/QuizDemo";
import { Collections } from "@/components/Collections";
import { Authors } from "@/components/Authors";
import { Premium } from "@/components/Premium";
import { Faq, FinalCta, Footer, Testimonials } from "@/components/Closing";

export default function Home() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <Proof />
        <Feed />
        <ReaderStory />
        <Blocker />
        <QuizDemo />
        <Collections />
        <Authors />
        <Premium />
        <Testimonials />
        <Faq />
        <FinalCta />
      </main>
      <Footer />
    </>
  );
}
