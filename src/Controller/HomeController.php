<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class HomeController extends AbstractController
{
    #[Route('/', name: 'app_home')]
    public function index(EntityManagerInterface $em): Response
    {
        $dbWorking = false;

        try {
            $conn = $em->getConnection();
            $conn->executeQuery('SELECT 1');
            $dbWorking = true;
        } catch (\Throwable $e) {
            $dbWorking = false;
        }

        $response = $this->render('home/index.html.twig', [
            'controller_name' => 'HomeController',
            'db_working' => $dbWorking,
        ]);

        $response->headers->addCacheControlDirective('no-store', true);
        $response->headers->addCacheControlDirective('no-cache', true);
        $response->headers->addCacheControlDirective('must-revalidate', true);
        $response->headers->set('Pragma', 'no-cache');

        return $response;
    }
}
